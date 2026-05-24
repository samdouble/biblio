package main

import (
	"context"
	"os"
	"testing"
	"time"

	"tsundoku-api/db"
	"tsundoku-api/libraries"
	"tsundoku-api/testutil"
	"tsundoku-api/types"
)

func TestMain_EmptyUserId(t *testing.T) {
	ctx := context.Background()
	event := types.CreateLibraryEvent{UserId: "", Name: "My Library"}
	resp, err := Main(ctx, event)
	if err == nil {
		t.Fatal("Main: expected error for empty userId")
	}
	if resp.Body.Error != "user id is required" {
		t.Errorf("Main: expected body error 'user id is required', got %q", resp.Body.Error)
	}
	if resp.Body.Library != nil {
		t.Error("Main: Library should be nil on error")
	}
}

func TestMain_EmptyName(t *testing.T) {
	ctx := context.Background()
	event := types.CreateLibraryEvent{UserId: "user-1", Name: ""}
	resp, err := Main(ctx, event)
	if err == nil {
		t.Fatal("Main: expected error for empty name")
	}
	if resp.Body.Error != "name is required" {
		t.Errorf("Main: expected body error 'name is required', got %q", resp.Body.Error)
	}
	if resp.Body.Library != nil {
		t.Error("Main: Library should be nil on error")
	}
}

func TestMain_WhitespaceOnlyName(t *testing.T) {
	ctx := context.Background()
	event := types.CreateLibraryEvent{UserId: "user-1", Name: "   "}
	resp, err := Main(ctx, event)
	if err == nil {
		t.Fatal("Main: expected error for whitespace-only name")
	}
	if resp.Body.Error != "name is required" {
		t.Errorf("Main: expected body error 'name is required', got %q", resp.Body.Error)
	}
}

func TestMain_CreatesLibrary(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "createlib")
	ctx := context.Background()
	c7 := 7
	resp, err := Main(ctx, types.CreateLibraryEvent{
		UserId: "user-new",
		Name:   "Shelf A",
		Color:  &c7,
	})
	if err != nil {
		t.Fatalf("Main: %v", err)
	}
	if resp.Body.Error != "" {
		t.Fatalf("Main: unexpected error %q", resp.Body.Error)
	}
	lib := resp.Body.Library
	if lib == nil {
		t.Fatal("Main: expected Library in response")
	}
	if lib.Id == "" || lib.Name != "Shelf A" {
		t.Fatalf("Main: unexpected library %+v", lib)
	}
	if lib.Color == nil || *lib.Color != 7 {
		t.Fatalf("Main: expected color 7, got %+v", lib.Color)
	}
	if _, err := time.Parse(time.RFC3339, lib.CreatedAt); err != nil {
		t.Fatalf("CreatedAt not RFC3339: %q", lib.CreatedAt)
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))
	list, err := libraries.GetByUserId(database, "user-new")
	if err != nil {
		t.Fatalf("GetByUserId: %v", err)
	}
	if len(list) != 1 {
		t.Fatalf("expected 1 library in DB, got %+v", list)
	}
	if list[0].Id != lib.Id || list[0].Name != "Shelf A" || list[0].UserId != "user-new" {
		t.Fatalf("unexpected stored library %+v", list[0])
	}
	if list[0].Color == nil || *list[0].Color != 7 {
		t.Fatalf("unexpected color in DB %+v", list[0].Color)
	}
}
