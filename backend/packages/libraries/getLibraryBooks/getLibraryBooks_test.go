package main

import (
	"context"
	"testing"

	"biblio-api/types"
)

func TestMain_EmptyUserId(t *testing.T) {
	ctx := context.Background()
	event := types.GetLibraryBooksEvent{UserId: "", LibraryId: "lib-1"}
	resp, err := Main(ctx, event)
	if err == nil {
		t.Fatal("Main: expected error for empty userId")
	}
	if resp.Body.Error != "userId and libraryId are required" {
		t.Errorf("Main: expected body error 'userId and libraryId are required', got %q", resp.Body.Error)
	}
	if resp.Body.BookIds != nil {
		t.Error("Main: BookIds should be nil on error")
	}
}

func TestMain_EmptyLibraryId(t *testing.T) {
	ctx := context.Background()
	event := types.GetLibraryBooksEvent{UserId: "user-1", LibraryId: "  "}
	resp, err := Main(ctx, event)
	if err == nil {
		t.Fatal("Main: expected error for empty libraryId")
	}
	if resp.Body.Error != "userId and libraryId are required" {
		t.Errorf("Main: expected body error 'userId and libraryId are required', got %q", resp.Body.Error)
	}
}
