package main

import (
	"context"
	"log"
	"os"
	"regexp"
	"strings"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"

	"biblio-api/db"
	"biblio-api/types"
)

const defaultLimit = 20
const maxLimit = 100

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
	defer db.CloseClientDB()
	database := client.Database(os.Getenv("MONGO_DBNAME"))
	coll := database.Collection("books")

	escaped := regexp.QuoteMeta(query)
	pattern := bson.M{"$regex": escaped, "$options": "i"}

	filter := bson.M{
		"$or": []bson.M{
			{"volumeInfo.title": pattern},
			{"volumeInfo.authors": pattern},
			{"isbn": pattern},
		},
	}

	opts := options.Find().SetLimit(int64(limit))
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
