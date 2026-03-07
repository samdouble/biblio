package main

import (
	"context"
	"log"
	"os"
	"strings"

	"biblio-api/db"
	"biblio-api/types"
)

func Main(ctx context.Context, event types.GetBooksByAuthorEvent) (types.GetBooksByAuthorResponse, error) {
	author := strings.TrimSpace(event.Author)
	if author == "" {
		return types.GetBooksByAuthorResponse{
			Body: types.GetBooksByAuthorResponseBody{Books: []interface{}{}, Error: "author is required"},
		}, nil
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	if cached, ok, err := getCachedBooks(database, author); err != nil {
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

	resp, err := fetchBooksByAuthorFromIsbnDb(author)
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

	_ = setCachedBooks(database, author, out)

	return types.GetBooksByAuthorResponse{
		Body: types.GetBooksByAuthorResponseBody{Books: out},
	}, nil
}
