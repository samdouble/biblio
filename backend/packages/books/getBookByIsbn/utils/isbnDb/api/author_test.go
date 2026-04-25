package api

import (
	"os"
	"strings"
	"testing"
)

func TestGetBooksByAuthor_MissingApiKey(t *testing.T) {
	_ = os.Unsetenv("ISBNDB_API_KEY")
	_, err := GetBooksByAuthor("Ada Lovelace")
	if err == nil {
		t.Fatal("expected error when ISBNDB_API_KEY is missing")
	}
	if !strings.Contains(err.Error(), "ISBNDB_API_KEY is not set") {
		t.Fatalf("unexpected error: %v", err)
	}
}
