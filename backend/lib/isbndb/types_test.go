package isbndb

import (
	"encoding/json"
	"testing"
)

func TestBooksResponse_UnmarshalJSON_dataOrBooks(t *testing.T) {
	var resp BooksResponse
	if err := json.Unmarshal([]byte(`{"data":[{"title":"A","isbn13":"978-1"}]}`), &resp); err != nil {
		t.Fatalf("unmarshal data: %v", err)
	}
	if len(resp.Books) != 1 || resp.Books[0].Title != "A" {
		t.Fatalf("unexpected books from data: %+v", resp.Books)
	}

	resp = BooksResponse{}
	if err := json.Unmarshal([]byte(`{"books":[{"title":"B","isbn13":"978-2"}]}`), &resp); err != nil {
		t.Fatalf("unmarshal books: %v", err)
	}
	if len(resp.Books) != 1 || resp.Books[0].Title != "B" {
		t.Fatalf("unexpected books from books key: %+v", resp.Books)
	}
}

func TestUpdatedFeedResponse_UnmarshalJSON(t *testing.T) {
	var resp UpdatedFeedResponse
	if err := json.Unmarshal([]byte(`{"updates":[{"isbn13":"978-1","lastUpdated":"2026-01-01"}]}`), &resp); err != nil {
		t.Fatalf("unmarshal updates: %v", err)
	}
	if len(resp.Updates) != 1 || resp.Updates[0].PrimaryISBN() != "978-1" {
		t.Fatalf("unexpected updates: %+v", resp.Updates)
	}
}

func TestBook_PrimaryISBN(t *testing.T) {
	if got := (Book{ISBN13: "978-13", ISBN: "978-10"}).PrimaryISBN(); got != "978-13" {
		t.Fatalf("PrimaryISBN = %q, want 978-13", got)
	}
	if got := (Book{ISBN: "978-10"}).PrimaryISBN(); got != "978-10" {
		t.Fatalf("PrimaryISBN fallback = %q, want 978-10", got)
	}
}
