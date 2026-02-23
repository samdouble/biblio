package main

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"biblio-api/models"
	"biblio-api/types"
)

func TestSimpleReturn(t *testing.T) {
	mockServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{
			"kind": "books#volumes",
			"totalItems": 1,
			"items": [
				{
					"id": "test-google-id",
					"volumeInfo": {
						"title": "Code Complete",
						"authors": ["Steve McConnell"],
						"publisher": "Microsoft Press",
						"publishedDate": "2004",
						"pageCount": 960
					}
				}
			]
		}`))
	}))
	defer mockServer.Close()
	originalURL := models.GoogleBooksAPIBaseURL
	models.GoogleBooksAPIBaseURL = mockServer.URL
	defer func() { models.GoogleBooksAPIBaseURL = originalURL }()

	ctx := context.Background()
	ctx = context.WithValue(ctx, "function_version", "Test")
	event := types.Event{Isbn: "0735619670"}
	msg, err := Main(ctx, event)

	if err != nil {
		t.Fatalf("TestSimpleReturn returned error: %v", err)
	}

	if len(msg.Body.Books) == 0 {
		t.Fatalf("TestSimpleReturn expected books to be returned, got empty response")
	}

	firstBook, ok := msg.Body.Books[0].(types.Book)
	if !ok {
		t.Fatalf("TestSimpleReturn expected first book to be of type types.Book")
	}

	if firstBook.Isbn != event.Isbn {
		t.Fatalf("TestSimpleReturn expected ISBN %s, got %s", event.Isbn, firstBook.Isbn)
	}
	if firstBook.VolumeInfo.Title != "Code Complete" {
		t.Fatalf("TestSimpleReturn expected title 'Code Complete', got %s", firstBook.VolumeInfo.Title)
	}
}
