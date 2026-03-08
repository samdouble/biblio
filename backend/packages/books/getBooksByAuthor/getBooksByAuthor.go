package main

import (
	"context"
	"log"
	"os"
	"strings"

	"go.mongodb.org/mongo-driver/mongo"

	"biblio-api/db"
	"biblio-api/types"
)

var (
	getCachedBooksFn   = getCachedBooks
	setCachedBooksFn   = setCachedBooks
	fetchAuthorBooksFn = fetchBooksByAuthorFromIsbnDb
)

func Main(ctx context.Context, event types.GetBooksByAuthorEvent) (types.GetBooksByAuthorResponse, error) {
	database := db.ResolveClientDB(os.Getenv("MONGO_URL")).Database(os.Getenv("MONGO_DBNAME"))
	return mainWithDB(ctx, event, database)
}

func mainWithDB(ctx context.Context, event types.GetBooksByAuthorEvent, database *mongo.Database) (types.GetBooksByAuthorResponse, error) {
	author := strings.TrimSpace(event.Author)
	if author == "" {
		return types.GetBooksByAuthorResponse{
			Body: types.GetBooksByAuthorResponseBody{Books: []interface{}{}, Error: "author is required"},
		}, nil
	}

	if cached, ok, err := getCachedBooksFn(database, author); err != nil {
		log.Printf("getCachedBooks: %v", err)
		return types.GetBooksByAuthorResponse{
			Body: types.GetBooksByAuthorResponseBody{Error: "cache error"},
		}, err
	} else if ok {
		books, _ := cached.([]interface{})
		if books == nil {
			books = []interface{}{}
		}
		return types.GetBooksByAuthorResponse{
			Body: types.GetBooksByAuthorResponseBody{Books: books},
		}, nil
	}

	resp, err := fetchAuthorBooksFn(author)
	if err != nil {
		log.Printf("fetchBooksByAuthorFromIsbnDb: %v", err)
		return types.GetBooksByAuthorResponse{
			Body: types.GetBooksByAuthorResponseBody{Error: "failed to fetch books by author"},
		}, err
	}

	out := make([]interface{}, 0, len(resp.Books))
	for i := range resp.Books {
		bo := isbnDbBookToOutput(&resp.Books[i])
		out = append(out, bo)
	}

	_ = setCachedBooksFn(database, author, out)

	return types.GetBooksByAuthorResponse{
		Body: types.GetBooksByAuthorResponseBody{Books: out},
	}, nil
}
