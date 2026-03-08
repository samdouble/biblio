package main

import (
	"context"
	"testing"

	"go.mongodb.org/mongo-driver/mongo"

	"biblio-api/types"
)

func TestMain_EmptyAuthor(t *testing.T) {
	ctx := context.Background()
	event := types.GetBooksByAuthorEvent{Author: ""}
	resp, err := mainWithDB(ctx, event, nil)
	if err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}
	if resp.Body.Error != "author is required" {
		t.Errorf("expected error 'author is required', got %q", resp.Body.Error)
	}
	if len(resp.Body.Books) != 0 {
		t.Error("expected no books on validation error")
	}
}

func TestMain_WhitespaceAuthor(t *testing.T) {
	ctx := context.Background()
	event := types.GetBooksByAuthorEvent{Author: "   "}
	resp, err := mainWithDB(ctx, event, nil)
	if err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}
	if resp.Body.Error != "author is required" {
		t.Errorf("expected error 'author is required', got %q", resp.Body.Error)
	}
}

func TestMain_CacheHit_ReturnsBooksFromLookupWithoutFetching(t *testing.T) {
	ctx := context.Background()
	cachedIsbns := []string{"978-0-123"}
	cachedBooks := []interface{}{
		types.BookOutput{
			Id:   "978-0-123",
			Isbn: "978-0-123",
			VolumeInfo: types.VolumeInfo{Title: "Cached Book", Authors: []string{"Jane Doe"}},
		},
	}
	fetchCalled := false
	setCalled := false

	origGet := getCachedIsbnsFn
	origSet := setCachedIsbnsFn
	origFetch := fetchAuthorBooksFn
	origGetBooks := getBooksByIsbnsFn
	defer func() {
		getCachedIsbnsFn = origGet
		setCachedIsbnsFn = origSet
		fetchAuthorBooksFn = origFetch
		getBooksByIsbnsFn = origGetBooks
	}()

	getCachedIsbnsFn = func(_ *mongo.Database, author string) ([]string, bool, error) {
		if author != "Jane Doe" {
			return nil, false, nil
		}
		return cachedIsbns, true, nil
	}
	setCachedIsbnsFn = func(_ *mongo.Database, _ string, _ []string) error {
		setCalled = true
		return nil
	}
	fetchAuthorBooksFn = func(author string) (*isbnDbAuthorResponse, error) {
		fetchCalled = true
		return nil, nil
	}
	getBooksByIsbnsFn = func(_ *mongo.Database, isbns []string) ([]interface{}, error) {
		if len(isbns) == 1 && isbns[0] == "978-0-123" {
			return cachedBooks, nil
		}
		return nil, nil
	}

	event := types.GetBooksByAuthorEvent{Author: "Jane Doe"}
	resp, err := mainWithDB(ctx, event, nil)
	if err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}
	if resp.Body.Error != "" {
		t.Errorf("expected no error, got %q", resp.Body.Error)
	}
	if fetchCalled {
		t.Error("cache hit should not call fetch")
	}
	if setCalled {
		t.Error("cache hit should not call set")
	}
	if len(resp.Body.Books) != 1 {
		t.Errorf("expected 1 cached book, got %d", len(resp.Body.Books))
	}
}

func TestMain_CacheMiss_InsertsBooksAndCachesIsbns(t *testing.T) {
	ctx := context.Background()
	mockBooks := []isbnDbBook{
		{Title: "Book One", ISBN: "111", ISBN13: "978-111", Authors: []string{"Alice"}},
	}
	var setAuthor string
	var setIsbns []string

	origGet := getCachedIsbnsFn
	origSet := setCachedIsbnsFn
	origFetch := fetchAuthorBooksFn
	origInsert := insertAuthorBooksFn
	origGetBooks := getBooksByIsbnsFn
	defer func() {
		getCachedIsbnsFn = origGet
		setCachedIsbnsFn = origSet
		fetchAuthorBooksFn = origFetch
		insertAuthorBooksFn = origInsert
		getBooksByIsbnsFn = origGetBooks
	}()

	getCachedIsbnsFn = func(_ *mongo.Database, _ string) ([]string, bool, error) {
		return nil, false, nil
	}
	setCachedIsbnsFn = func(_ *mongo.Database, author string, isbns []string) error {
		setAuthor = author
		setIsbns = isbns
		return nil
	}
	fetchAuthorBooksFn = func(author string) (*isbnDbAuthorResponse, error) {
		if author != "Alice" {
			return &isbnDbAuthorResponse{Author: author, Books: nil}, nil
		}
		return &isbnDbAuthorResponse{Author: author, Books: mockBooks}, nil
	}
	insertAuthorBooksFn = func(_ *mongo.Database, books []isbnDbBook) ([]string, error) {
		isbns := make([]string, 0, len(books))
		for i := range books {
			if books[i].ISBN13 != "" {
				isbns = append(isbns, books[i].ISBN13)
			} else {
				isbns = append(isbns, books[i].ISBN)
			}
		}
		return isbns, nil
	}
	getBooksByIsbnsFn = func(_ *mongo.Database, isbns []string) ([]interface{}, error) {
		out := make([]interface{}, 0, len(isbns))
		for _, isbn := range isbns {
			out = append(out, types.BookOutput{Id: isbn, Isbn: isbn, VolumeInfo: types.VolumeInfo{Title: "Book One", Authors: []string{"Alice"}}})
		}
		return out, nil
	}

	event := types.GetBooksByAuthorEvent{Author: "Alice"}
	resp, err := mainWithDB(ctx, event, nil)
	if err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}
	if resp.Body.Error != "" {
		t.Errorf("expected no error, got %q", resp.Body.Error)
	}
	if setAuthor != "Alice" {
		t.Errorf("setCachedIsbns called with author %q, want Alice", setAuthor)
	}
	if len(setIsbns) != 1 || setIsbns[0] != "978-111" {
		t.Errorf("setCachedIsbns called with isbns %v, want [978-111]", setIsbns)
	}
	if len(resp.Body.Books) != 1 {
		t.Errorf("expected 1 book in response, got %d", len(resp.Body.Books))
	}
}

func TestMain_CacheError_ReturnsError(t *testing.T) {
	ctx := context.Background()
	origGet := getCachedIsbnsFn
	defer func() { getCachedIsbnsFn = origGet }()

	getCachedIsbnsFn = func(_ *mongo.Database, _ string) ([]string, bool, error) {
		return nil, false, context.DeadlineExceeded
	}

	event := types.GetBooksByAuthorEvent{Author: "Someone"}
	resp, err := mainWithDB(ctx, event, nil)
	if err == nil {
		t.Fatal("expected error when cache get fails")
	}
	if resp.Body.Error != "cache error" {
		t.Errorf("expected body error 'cache error', got %q", resp.Body.Error)
	}
}
