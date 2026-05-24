package main

import (
	"context"
	"os"
	"testing"
	"time"

	"tsunbooku-api/db"
	"tsunbooku-api/libraries"
	"tsunbooku-api/testutil"
	"tsunbooku-api/types"
)

func TestMain_EmptyUserId(t *testing.T) {
	ctx := context.Background()
	event := types.GetLibrariesEvent{UserId: ""}
	resp, err := Main(ctx, event)
	if err == nil {
		t.Fatal("Main: expected error for empty userId")
	}
	if resp.Body.Error != "user id is required" {
		t.Errorf("Main: expected body error 'user id is required', got %q", resp.Body.Error)
	}
	if len(resp.Body.Libraries) != 0 {
		t.Error("Main: Libraries should be empty on error")
	}
}

func TestMain_WhitespaceOnlyUserId(t *testing.T) {
	ctx := context.Background()
	event := types.GetLibrariesEvent{UserId: "  \t "}
	resp, err := Main(ctx, event)
	if err == nil {
		t.Fatal("Main: expected error for whitespace-only userId")
	}
	if resp.Body.Error != "user id is required" {
		t.Errorf("Main: expected body error 'user id is required', got %q", resp.Body.Error)
	}
}

func TestMain_ListsNoLibrariesForNewUser(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "getlibs")
	ctx := context.Background()
	resp, err := Main(ctx, types.GetLibrariesEvent{UserId: "user-empty"})
	if err != nil {
		t.Fatalf("Main: %v", err)
	}
	if resp.Body.Error != "" {
		t.Fatalf("Main: unexpected error %q", resp.Body.Error)
	}
	if len(resp.Body.Libraries) != 0 {
		t.Fatalf("Main: expected no libraries, got %d", len(resp.Body.Libraries))
	}
}

func TestMain_ListsLibrariesForUser(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "getlibs")
	ctx := context.Background()
	now := time.Now().UTC().Truncate(time.Millisecond)
	c5 := 5
	seed := []libraries.Library{
		{Id: "lib-1", UserId: "user-a", Name: "Alpha", Color: &c5, CreatedAt: now},
		{Id: "lib-2", UserId: "user-a", Name: "Beta", CreatedAt: now.Add(time.Minute)},
		{Id: "lib-other", UserId: "user-b", Name: "Other", CreatedAt: now},
	}
	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))
	for _, lib := range seed {
		if err := libraries.Insert(database, lib); err != nil {
			t.Fatalf("Insert: %v", err)
		}
	}

	resp, err := Main(ctx, types.GetLibrariesEvent{UserId: "user-a"})
	if err != nil {
		t.Fatalf("Main: %v", err)
	}
	if resp.Body.Error != "" {
		t.Fatalf("Main: unexpected error %q", resp.Body.Error)
	}
	if len(resp.Body.Libraries) != 2 {
		t.Fatalf("Main: expected 2 libraries, got %+v", resp.Body.Libraries)
	}
	byID := make(map[string]types.LibraryPayload)
	for _, p := range resp.Body.Libraries {
		byID[p.Id] = p
	}
	a, b := byID["lib-1"], byID["lib-2"]
	if a.Name != "Alpha" || b.Name != "Beta" {
		t.Fatalf("unexpected names: %+v %+v", a, b)
	}
	if a.Color == nil || *a.Color != 5 {
		t.Fatalf("expected color 5 on Alpha, got %+v", a.Color)
	}
	if b.Color != nil {
		t.Fatalf("expected no color on Beta, got %+v", b.Color)
	}
	if _, err := time.Parse(time.RFC3339, a.CreatedAt); err != nil {
		t.Fatalf("CreatedAt not RFC3339: %q", a.CreatedAt)
	}
}
