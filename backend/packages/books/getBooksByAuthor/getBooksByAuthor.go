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

// Test hooks for cache, fetcher, books insert and lookup.
var (
	getCachedIsbnsFn    = getCachedIsbns
	setCachedIsbnsFn    = setCachedIsbns
	fetchAuthorBooksFn  = fetchBooksByAuthorFromIsbnDb
	insertAuthorBooksFn = insertAuthorBooks
	getBooksByIsbnsFn   = getBooksByIsbns
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

	isbns, ok, err := getCachedIsbnsFn(database, author)
	if err != nil {
		log.Printf("getCachedIsbns: %v", err)
		return types.GetBooksByAuthorResponse{
			Body: types.GetBooksByAuthorResponseBody{Error: "cache error"},
		}, err
	}
	if ok {
		books, err := getBooksByIsbnsFn(database, isbns)
		if err != nil {
			log.Printf("getBooksByIsbns: %v", err)
			return types.GetBooksByAuthorResponse{
				Body: types.GetBooksByAuthorResponseBody{Error: "failed to load books"},
			}, err
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

	isbns, err = insertAuthorBooksFn(database, resp.Books)
	if err != nil {
		log.Printf("insertAuthorBooks: %v", err)
	}
	_ = setCachedIsbnsFn(database, author, isbns)

	books, err := getBooksByIsbnsFn(database, isbns)
	if err != nil {
		log.Printf("getBooksByIsbns: %v", err)
		return types.GetBooksByAuthorResponse{
			Body: types.GetBooksByAuthorResponseBody{Error: "failed to load books"},
		}, err
	}

	return types.GetBooksByAuthorResponse{
		Body: types.GetBooksByAuthorResponseBody{Books: books},
	}, nil
}
