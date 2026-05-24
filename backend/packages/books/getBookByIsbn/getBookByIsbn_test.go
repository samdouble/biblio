package main

import (
	"context"
	"testing"

	"tsunbooku-api/types"
)

func TestMain_RequiresIsbn(t *testing.T) {
	ctx := context.Background()
	_, err := Main(ctx, types.GetBookByIsbnEvent{Isbn: ""})
	if err == nil {
		t.Fatalf("expected error when ISBN is empty")
	}
}
