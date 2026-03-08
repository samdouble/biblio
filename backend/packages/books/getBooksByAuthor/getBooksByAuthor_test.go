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

func TestMain_CacheHit_ReturnsCachedWithoutFetching(t *testing.T) {
	ctx := context.Background()
	cachedBooks := []interface{}{
		types.BookOutput{
			Id:   "978-0-123",
			Isbn: "0123456789",
			VolumeInfo: types.VolumeInfo{Title: "Cached Book", Authors: []string{"Author"}},
		},
	}
	fetchCalled := false
	setCalled := false

	origGet := getCachedBooksFn
	origSet := setCachedBooksFn
	origFetch := fetchAuthorBooksFn
	defer func() {
		getCachedBooksFn = origGet
		setCachedBooksFn = origSet
		fetchAuthorBooksFn = origFetch
	}()

	getCachedBooksFn = func(_ *mongo.Database, author string) (interface{}, bool, error) {
		if author != "Jane Doe" {
			return nil, false, nil
		}
		return cachedBooks, true, nil
	}
	setCachedBooksFn = func(_ *mongo.Database, _ string, _ interface{}) error {
		setCalled = true
		return nil
	}
	fetchAuthorBooksFn = func(author string) (*isbnDbAuthorResponse, error) {
		fetchCalled = true
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

func TestMain_CacheMiss_FetchesAndCaches(t *testing.T) {
	ctx := context.Background()
	mockBooks := []isbnDbBook{
		{Title: "Book One", ISBN: "111", ISBN13: "978-111", Authors: []string{"Alice"}},
	}
	var setAuthor string
	var setBooks interface{}

	origGet := getCachedBooksFn
	origSet := setCachedBooksFn
	origFetch := fetchAuthorBooksFn
	defer func() {
		getCachedBooksFn = origGet
		setCachedBooksFn = origSet
		fetchAuthorBooksFn = origFetch
	}()

	getCachedBooksFn = func(_ *mongo.Database, _ string) (interface{}, bool, error) {
		return nil, false, nil
	}
	setCachedBooksFn = func(_ *mongo.Database, author string, books interface{}) error {
		setAuthor = author
		setBooks = books
		return nil
	}
	fetchAuthorBooksFn = func(author string) (*isbnDbAuthorResponse, error) {
		if author != "Alice" {
			return &isbnDbAuthorResponse{Author: author, Books: nil}, nil
		}
		return &isbnDbAuthorResponse{Author: author, Books: mockBooks}, nil
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
		t.Errorf("setCachedBooks called with author %q, want Alice", setAuthor)
	}
	if setBooks == nil {
		t.Fatal("setCachedBooks should have been called with books")
	}
	sl, ok := setBooks.([]interface{})
	if !ok || len(sl) != 1 {
		t.Errorf("expected 1 book to be cached, got %T len %d", setBooks, len(sl))
	}
	if len(resp.Body.Books) != 1 {
		t.Errorf("expected 1 book in response, got %d", len(resp.Body.Books))
	}
}

func TestMain_CacheError_ReturnsError(t *testing.T) {
	ctx := context.Background()
	origGet := getCachedBooksFn
	defer func() { getCachedBooksFn = origGet }()

	getCachedBooksFn = func(_ *mongo.Database, _ string) (interface{}, bool, error) {
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
