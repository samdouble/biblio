package main

import (
	"context"
	"log"
	"os"
	"regexp"
	"strings"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"tsunbooku-api/db"
	"tsunbooku-api/types"
)

const defaultLimit = 20
const maxLimit = 100

var diacriticCharClasses = map[rune]string{
	'a': "[aàáâãäåāăą]",
	'c': "[cçćĉċč]",
	'd': "[dďđ]",
	'e': "[eèéêëēĕėęě]",
	'g': "[gĝğġģ]",
	'i': "[iìíîïĩīĭįı]",
	'l': "[lĺļľł]",
	'n': "[nñńņňŋ]",
	'o': "[oòóôõöøōŏő]",
	'r': "[rŕŗř]",
	's': "[sśŝşš]",
	't': "[tţťŧ]",
	'u': "[uùúûüũūŭůűų]",
	'y': "[yýÿŷ]",
	'z': "[zźżž]",
}

func buildAccentInsensitivePattern(query string) string {
	var b strings.Builder
	for _, r := range strings.ToLower(query) {
		if cls, ok := diacriticCharClasses[r]; ok {
			b.WriteString(cls)
			continue
		}
		b.WriteString(regexp.QuoteMeta(string(r)))
	}
	return b.String()
}

func Main(ctx context.Context, event types.SearchBooksEvent) (types.SearchBooksResponse, error) {
	query := strings.TrimSpace(event.Query)
	if query == "" {
		return types.SearchBooksResponse{
			Body: types.SearchBooksResponseBody{Books: []interface{}{}},
		}, nil
	}

	limit := event.Limit
	if limit <= 0 {
		limit = defaultLimit
	}
	if limit > maxLimit {
		limit = maxLimit
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))
	coll := database.Collection("books")

	pattern := bson.M{"$regex": buildAccentInsensitivePattern(query), "$options": "i"}

	filter := bson.M{
		"$or": []bson.M{
			{"volumeInfo.title": pattern},
			{"volumeInfo.authors": pattern},
			{"isbn": pattern},
		},
	}

	opts := options.Find().SetLimit(int64(limit)).SetCollation(&options.Collation{
		Locale:   "en",
		Strength: 1, // case and diacritic insensitive ordering/comparison where supported
	})
	cursor, err := coll.Find(ctx, filter, opts)
	if err != nil {
		log.Printf("books.Find: %v", err)
		return types.SearchBooksResponse{
			Body: types.SearchBooksResponseBody{Error: "search failed"},
		}, err
	}
	defer cursor.Close(ctx)

	var books []types.Book
	if err := cursor.All(ctx, &books); err != nil {
		log.Printf("cursor.All: %v", err)
		return types.SearchBooksResponse{
			Body: types.SearchBooksResponseBody{Error: "search failed"},
		}, err
	}

	out := make([]interface{}, 0, len(books))
	for i := range books {
		out = append(out, books[i])
	}

	return types.SearchBooksResponse{
		Body: types.SearchBooksResponseBody{Books: out},
	}, nil
}
