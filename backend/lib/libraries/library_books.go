package libraries

import (
	"context"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

const LibraryBooksCollectionName = "library_books"

type LibraryBookLink struct {
	LibraryId string    `bson:"libraryId"`
	UserId    string    `bson:"userId"`
	BookId    string    `bson:"bookId"`
	AddedAt   time.Time `bson:"addedAt"`
}

type LibraryBookEntry struct {
	BookId  string
	AddedAt time.Time
}

func ensureLibraryBooksIndexes(ctx context.Context, coll *mongo.Collection) error {
	_, err := coll.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{
			{Key: "userId", Value: 1},
			{Key: "libraryId", Value: 1},
			{Key: "bookId", Value: 1},
		},
		Options: options.Index().SetUnique(true).SetName("userId_libraryId_bookId_unique"),
	})
	return err
}

func edgeFilter(libraryId, userId string) bson.M {
	return bson.M{
		"libraryId": libraryId,
		"userId":    userId,
		"bookId":    bson.M{"$exists": true, "$ne": ""},
	}
}

func migrateLegacyLibraryBooksDoc(ctx context.Context, coll *mongo.Collection, libraryId, userId string) error {
	var legacy struct {
		BookIds []string `bson:"bookIds"`
	}
	err := coll.FindOne(ctx, bson.M{
		"libraryId": libraryId,
		"userId":    userId,
		"bookIds":   bson.M{"$exists": true},
	}).Decode(&legacy)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil
		}
		return err
	}
	now := time.Now().UTC()
	var docs []any
	for _, bid := range legacy.BookIds {
		bid = strings.TrimSpace(bid)
		if bid == "" {
			continue
		}
		docs = append(docs, bson.M{
			"libraryId": libraryId,
			"userId":    userId,
			"bookId":    bid,
			"addedAt":   now,
		})
	}
	if len(docs) > 0 {
		if _, err := coll.InsertMany(ctx, docs); err != nil {
			return err
		}
	}
	_, err = coll.DeleteOne(ctx, bson.M{
		"libraryId": libraryId,
		"userId":    userId,
		"bookIds":   bson.M{"$exists": true},
	})
	return err
}

func dedupeBookIDs(bookIds []string) []string {
	seen := make(map[string]struct{})
	var out []string
	for _, s := range bookIds {
		s = strings.TrimSpace(s)
		if s == "" {
			continue
		}
		if _, ok := seen[s]; ok {
			continue
		}
		seen[s] = struct{}{}
		out = append(out, s)
	}
	return out
}

func GetLibraryBookEntries(database *mongo.Database, libraryId, userId string) ([]LibraryBookEntry, error) {
	coll := database.Collection(LibraryBooksCollectionName)
	ctx := context.TODO()
	if err := ensureLibraryBooksIndexes(ctx, coll); err != nil {
		return nil, err
	}
	if err := migrateLegacyLibraryBooksDoc(ctx, coll, libraryId, userId); err != nil {
		return nil, err
	}
	opts := options.Find().SetSort(bson.D{{Key: "addedAt", Value: 1}})
	cur, err := coll.Find(ctx, edgeFilter(libraryId, userId), opts)
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)
	var entries []LibraryBookEntry
	for cur.Next(ctx) {
		var link LibraryBookLink
		if err := cur.Decode(&link); err != nil {
			return nil, err
		}
		entries = append(entries, LibraryBookEntry{BookId: link.BookId, AddedAt: link.AddedAt.UTC()})
	}
	if err := cur.Err(); err != nil {
		return nil, err
	}
	if entries == nil {
		entries = []LibraryBookEntry{}
	}
	return entries, nil
}

func GetLibraryBookIds(database *mongo.Database, libraryId, userId string) ([]string, error) {
	entries, err := GetLibraryBookEntries(database, libraryId, userId)
	if err != nil {
		return nil, err
	}
	out := make([]string, len(entries))
	for i, e := range entries {
		out[i] = e.BookId
	}
	return out, nil
}

func SetLibraryBookIds(database *mongo.Database, libraryId, userId string, bookIds []string) error {
	wanted := dedupeBookIDs(bookIds)
	coll := database.Collection(LibraryBooksCollectionName)
	ctx := context.TODO()
	if err := ensureLibraryBooksIndexes(ctx, coll); err != nil {
		return err
	}
	if err := migrateLegacyLibraryBooksDoc(ctx, coll, libraryId, userId); err != nil {
		return err
	}

	entries, err := GetLibraryBookEntries(database, libraryId, userId)
	if err != nil {
		return err
	}
	current := make(map[string]time.Time, len(entries))
	for _, e := range entries {
		current[e.BookId] = e.AddedAt
	}

	wantedSet := make(map[string]struct{}, len(wanted))
	for _, id := range wanted {
		wantedSet[id] = struct{}{}
	}

	var toRemove []string
	for id := range current {
		if _, ok := wantedSet[id]; !ok {
			toRemove = append(toRemove, id)
		}
	}
	var toAdd []string
	for _, id := range wanted {
		if _, ok := current[id]; !ok {
			toAdd = append(toAdd, id)
		}
	}

	if len(toRemove) > 0 {
		if _, err := coll.DeleteMany(ctx, bson.M{
			"libraryId": libraryId,
			"userId":    userId,
			"bookId":    bson.M{"$in": toRemove},
		}); err != nil {
			return err
		}
	}

	if len(toAdd) > 0 {
		now := time.Now().UTC()
		docs := make([]any, 0, len(toAdd))
		for _, bid := range toAdd {
			docs = append(docs, bson.M{
				"libraryId": libraryId,
				"userId":    userId,
				"bookId":    bid,
				"addedAt":   now,
			})
		}
		if _, err := coll.InsertMany(ctx, docs); err != nil {
			return err
		}
	}

	return nil
}
