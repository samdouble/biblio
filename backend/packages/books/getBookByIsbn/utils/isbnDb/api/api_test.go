package api

import (
	"os"
	"strings"
	"testing"
)

func TestSearchBooksByIsbn_MissingApiKey(t *testing.T) {
	_ = os.Unsetenv("ISBNDB_API_KEY")
	_, err := SearchBooksByIsbn("9781234567890")
	if err == nil {
		t.Fatal("expected error when ISBNDB_API_KEY is missing")
	}
	if !strings.Contains(err.Error(), "ISBNDB_API_KEY is not set") {
		t.Fatalf("unexpected error: %v", err)
	}
}
