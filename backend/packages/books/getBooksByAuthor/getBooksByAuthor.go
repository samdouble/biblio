package main

import (
	"context"
	"log"
	"os"
	"strings"

	"go.mongodb.org/mongo-driver/v2/mongo"

	"biblio-api/authors"
	"biblio-api/db"
	"biblio-api/types"
)

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
		if database != nil {
			if err := authors.UpsertNames(database, authorNamesFromBookDocs(books)); err != nil {
				log.Printf("authors.UpsertNames: %v", err)
			}
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
	if database != nil {
		if err := authors.UpsertNames(database, authorNamesFromBookDocs(books)); err != nil {
			log.Printf("authors.UpsertNames: %v", err)
		}
	}

	return types.GetBooksByAuthorResponse{
		Body: types.GetBooksByAuthorResponseBody{Books: books},
	}, nil
}

func authorNamesFromBookDocs(books []interface{}) []string {
	var names []string
	for _, item := range books {
		switch doc := item.(type) {
		case bookDoc:
			names = append(names, doc.VolumeInfo.Authors...)
		case types.BookOutput:
			names = append(names, doc.VolumeInfo.Authors...)
		case map[string]interface{}:
			if vol, ok := doc["volumeInfo"].(map[string]interface{}); ok {
				names = append(names, authorNamesFromVolumeInfo(vol)...)
			}
		}
	}
	return names
}

func authorNamesFromVolumeInfo(vol map[string]interface{}) []string {
	raw, ok := vol["authors"]
	if !ok {
		return nil
	}
	switch authors := raw.(type) {
	case []string:
		return authors
	case []interface{}:
		out := make([]string, 0, len(authors))
		for _, item := range authors {
			if name, ok := item.(string); ok {
				out = append(out, name)
			}
		}
		return out
	default:
		return nil
	}
}
