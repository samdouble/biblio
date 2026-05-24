package ingest

import (
	"context"
	"os"
	"strconv"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"tsunbooku-api/authors"
	"tsunbooku-api/books"
	"tsunbooku-api/isbndb"
)

const stateCollection = "ingest_state"
const feedStateID = "feed"

type feedState struct {
	ID              string    `bson:"_id"`
	LastUpdatedDate time.Time `bson:"lastUpdatedDate"`
	UpdatedAt       time.Time `bson:"updatedAt"`
}

type Config struct {
	FeedEnabled         bool
	MaxFeedPages        int
	FeedPageSize        int
	MaxAuthorsPerRun    int
	MaxPagesPerAuthor   int
	AuthorPageSize      int
	AuthorStaleDays     int
	BulkISBNBatchSize   int
}

type Result struct {
	FeedPagesFetched    int
	FeedISBNsFetched    int
	FeedBooksInserted   int
	AuthorsProcessed    int
	AuthorBooksInserted int
	StoppedOnRateLimit  bool
	FeedSkipped         bool
	FeedSkipReason      string
}

func ConfigFromEnv() Config {
	return Config{
		FeedEnabled:         envBool("INGEST_FEED_ENABLED", true),
		MaxFeedPages:        envInt("INGEST_MAX_FEED_PAGES", 3),
		FeedPageSize:        envInt("INGEST_FEED_PAGE_SIZE", 100),
		MaxAuthorsPerRun:    envInt("INGEST_MAX_AUTHORS_PER_RUN", 3),
		MaxPagesPerAuthor:   envInt("INGEST_MAX_PAGES_PER_AUTHOR", 2),
		AuthorPageSize:      envInt("INGEST_AUTHOR_PAGE_SIZE", 100),
		AuthorStaleDays:     envInt("INGEST_AUTHOR_STALE_DAYS", 30),
		BulkISBNBatchSize:   envInt("INGEST_BULK_ISBN_BATCH_SIZE", 100),
	}
}

func Run(ctx context.Context, database *mongo.Database, client *isbndb.Client, cfg Config) (Result, error) {
	var result Result

	if cfg.FeedEnabled {
		feedResult, err := ingestFeed(ctx, database, client, cfg)
		result.FeedPagesFetched = feedResult.pagesFetched
		result.FeedISBNsFetched = feedResult.isbnsFetched
		result.FeedBooksInserted = feedResult.booksInserted
		result.FeedSkipped = feedResult.skipped
		result.FeedSkipReason = feedResult.skipReason
		if err == isbndb.ErrRateLimit {
			result.StoppedOnRateLimit = true
			return result, nil
		}
		if err != nil {
			return result, err
		}
	}

	authorResult, err := ingestAuthors(ctx, database, client, cfg)
	result.AuthorsProcessed = authorResult.authorsProcessed
	result.AuthorBooksInserted = authorResult.booksInserted
	if err == isbndb.ErrRateLimit {
		result.StoppedOnRateLimit = true
		return result, nil
	}
	if err != nil {
		return result, err
	}

	return result, nil
}

type feedRunResult struct {
	pagesFetched  int
	isbnsFetched  int
	booksInserted int
	skipped       bool
	skipReason    string
}

func ingestFeed(ctx context.Context, database *mongo.Database, client *isbndb.Client, cfg Config) (feedRunResult, error) {
	var result feedRunResult
	lastUpdated, err := getFeedCursor(database)
	if err != nil {
		return result, err
	}

	var allISBNs []string
	for page := 1; page <= cfg.MaxFeedPages; page++ {
		if ctx.Err() != nil {
			return result, ctx.Err()
		}
		resp, err := client.FetchUpdatedISBNs(lastUpdated, page, cfg.FeedPageSize)
		if err != nil {
			if isFeedUnavailable(err) {
				result.skipped = true
				result.skipReason = err.Error()
				return result, nil
			}
			return result, err
		}
		result.pagesFetched++
		if len(resp.Updates) == 0 {
			break
		}
		for _, update := range resp.Updates {
			if isbn := update.PrimaryISBN(); isbn != "" {
				allISBNs = append(allISBNs, isbn)
			}
		}
		if len(resp.Updates) < cfg.FeedPageSize {
			break
		}
	}

	result.isbnsFetched = len(allISBNs)
	if len(allISBNs) == 0 {
		return result, nil
	}

	inserted, err := fetchAndInsertISBNs(database, client, allISBNs, cfg.BulkISBNBatchSize)
	result.booksInserted = inserted
	if err != nil {
		return result, err
	}

	if err := setFeedCursor(database, time.Now().UTC().AddDate(0, 0, -1)); err != nil {
		return result, err
	}
	return result, nil
}

type authorRunResult struct {
	authorsProcessed int
	booksInserted    int
}

func ingestAuthors(ctx context.Context, database *mongo.Database, client *isbndb.Client, cfg Config) (authorRunResult, error) {
	var result authorRunResult
	staleBefore := time.Now().UTC().AddDate(0, 0, -cfg.AuthorStaleDays)
	dueAuthors, err := authors.FindDueForIngest(database, cfg.MaxAuthorsPerRun, staleBefore)
	if err != nil {
		return result, err
	}

	for _, author := range dueAuthors {
		if ctx.Err() != nil {
			return result, ctx.Err()
		}
		inserted, ingestErr := ingestSingleAuthor(database, client, author.Name, cfg)
		result.authorsProcessed++
		result.booksInserted += inserted
		_ = authors.MarkIngested(database, author.Id, ingestErr)
		if ingestErr == isbndb.ErrRateLimit {
			return result, isbndb.ErrRateLimit
		}
		if ingestErr != nil {
			return result, ingestErr
		}
	}
	return result, nil
}

func ingestSingleAuthor(database *mongo.Database, client *isbndb.Client, authorName string, cfg Config) (int, error) {
	var allBooks []isbndb.Book
	for page := 1; page <= cfg.MaxPagesPerAuthor; page++ {
		resp, err := client.FetchAuthorBooks(authorName, page, cfg.AuthorPageSize)
		if err != nil {
			return 0, err
		}
		allBooks = append(allBooks, resp.Books...)
		if len(resp.Books) < cfg.AuthorPageSize {
			break
		}
	}
	inserted, _, err := books.InsertManyFromIsbnDb(database, allBooks)
	return inserted, err
}

func fetchAndInsertISBNs(database *mongo.Database, client *isbndb.Client, isbns []string, batchSize int) (int, error) {
	if batchSize <= 0 {
		batchSize = 100
	}
	totalInserted := 0
	for start := 0; start < len(isbns); start += batchSize {
		end := start + batchSize
		if end > len(isbns) {
			end = len(isbns)
		}
		batch := isbns[start:end]
		fetched, err := client.FetchBooksByISBNs(batch)
		if err != nil {
			return totalInserted, err
		}
		inserted, _, err := books.InsertManyFromIsbnDb(database, fetched)
		if err != nil {
			return totalInserted, err
		}
		totalInserted += inserted
	}
	return totalInserted, nil
}

func getFeedCursor(database *mongo.Database) (time.Time, error) {
	coll := database.Collection(stateCollection)
	var state feedState
	err := coll.FindOne(context.TODO(), bson.M{"_id": feedStateID}).Decode(&state)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return time.Now().UTC().AddDate(0, 0, -7), nil
		}
		return time.Time{}, err
	}
	if state.LastUpdatedDate.IsZero() {
		return time.Now().UTC().AddDate(0, 0, -7), nil
	}
	return state.LastUpdatedDate, nil
}

func setFeedCursor(database *mongo.Database, lastUpdated time.Time) error {
	coll := database.Collection(stateCollection)
	now := time.Now().UTC()
	_, err := coll.UpdateOne(
		context.TODO(),
		bson.M{"_id": feedStateID},
		bson.M{"$set": feedState{
			ID:              feedStateID,
			LastUpdatedDate: lastUpdated,
			UpdatedAt:       now,
		}},
		options.UpdateOne().SetUpsert(true),
	)
	return err
}

func isFeedUnavailable(err error) bool {
	if err == nil {
		return false
	}
	msg := err.Error()
	return strings.Contains(msg, "feed unavailable")
}

func envInt(key string, fallback int) int {
	raw := os.Getenv(key)
	if raw == "" {
		return fallback
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n <= 0 {
		return fallback
	}
	return n
}

func envBool(key string, fallback bool) bool {
	raw := os.Getenv(key)
	if raw == "" {
		return fallback
	}
	switch raw {
	case "1", "true", "TRUE", "yes", "YES":
		return true
	case "0", "false", "FALSE", "no", "NO":
		return false
	default:
		return fallback
	}
}
