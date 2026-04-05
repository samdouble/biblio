package libraries

import (
	"context"
	"fmt"
	"hash/fnv"
	"os"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func integrationMongoDB(t *testing.T) *mongo.Database {
	t.Helper()
	uri := os.Getenv("MONGO_URL")
	if uri == "" {
		t.Skip("MONGO_URL not set, skipping integration test")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	client, err := mongo.Connect(ctx, options.Client().
		ApplyURI(uri).
		SetConnectTimeout(5*time.Second).
		SetServerSelectionTimeout(5*time.Second))
	if err != nil {
		t.Fatalf("mongo connect: %v", err)
	}
	t.Cleanup(func() {
		_ = client.Disconnect(context.Background())
	})
	h := fnv.New32a()
	_, _ = h.Write([]byte(t.Name()))
	db := client.Database(fmt.Sprintf("t_lb_%08x", h.Sum32()))
	t.Cleanup(func() {
		_ = db.Drop(context.Background())
	})
	return db
}

func TestSetLibraryBookIds_writesEdgeDocumentsWithFields(t *testing.T) {
	db := integrationMongoDB(t)
	const libID, userID = "lib-a", "user-1"

	if err := SetLibraryBookIds(db, libID, userID, []string{"book-1", "book-2"}); err != nil {
		t.Fatalf("SetLibraryBookIds: %v", err)
	}

	ctx := context.Background()
	coll := db.Collection(LibraryBooksCollectionName)
	n, err := coll.CountDocuments(ctx, edgeFilter(libID, userID))
	if err != nil {
		t.Fatalf("CountDocuments: %v", err)
	}
	if n != 2 {
		t.Fatalf("expected 2 edge documents, got %d", n)
	}

	cur, err := coll.Find(ctx, edgeFilter(libID, userID))
	if err != nil {
		t.Fatalf("Find: %v", err)
	}
	defer cur.Close(ctx)

	byBook := make(map[string]LibraryBookLink)
	for cur.Next(ctx) {
		var doc LibraryBookLink
		if err := cur.Decode(&doc); err != nil {
			t.Fatalf("Decode: %v", err)
		}
		if doc.LibraryId != libID || doc.UserId != userID {
			t.Fatalf("wrong libraryId/userId: %+v", doc)
		}
		if doc.BookId == "" || doc.AddedAt.IsZero() {
			t.Fatalf("missing bookId or addedAt: %+v", doc)
		}
		if time.Since(doc.AddedAt.UTC()) > 2*time.Minute {
			t.Fatalf("addedAt looks wrong: %v", doc.AddedAt)
		}
		byBook[doc.BookId] = doc
	}
	if err := cur.Err(); err != nil {
		t.Fatalf("cursor: %v", err)
	}
	if len(byBook) != 2 {
		t.Fatalf("expected 2 distinct bookIds, got %d", len(byBook))
	}
}

func TestGetLibraryBookEntries_sortedByAddedAt_andLegacyMigration(t *testing.T) {
	db := integrationMongoDB(t)
	const libID, userID = "lib-mig", "user-mig"
	ctx := context.Background()
	coll := db.Collection(LibraryBooksCollectionName)

	_, err := coll.InsertOne(ctx, bson.M{
		"libraryId": libID,
		"userId":    userID,
		"bookIds":   []string{"legacy-1", "legacy-2"},
	})
	if err != nil {
		t.Fatalf("insert legacy doc: %v", err)
	}

	entries, err := GetLibraryBookEntries(db, libID, userID)
	if err != nil {
		t.Fatalf("GetLibraryBookEntries: %v", err)
	}
	if len(entries) != 2 {
		t.Fatalf("expected 2 entries after migration, got %d", len(entries))
	}
	got := map[string]bool{entries[0].BookId: true, entries[1].BookId: true}
	if !got["legacy-1"] || !got["legacy-2"] {
		t.Fatalf("unexpected book ids: %+v", entries)
	}
	if entries[0].AddedAt.IsZero() || entries[1].AddedAt.IsZero() {
		t.Fatal("expected non-zero addedAt on migrated edges")
	}
	if !entries[0].AddedAt.Equal(entries[1].AddedAt) {
		t.Fatal("migrated edges should share the same addedAt timestamp")
	}

	var legacyCount int64
	legacyCount, err = coll.CountDocuments(ctx, bson.M{
		"libraryId": libID,
		"userId":    userID,
		"bookIds":   bson.M{"$exists": true},
	})
	if err != nil {
		t.Fatalf("CountDocuments legacy: %v", err)
	}
	if legacyCount != 0 {
		t.Fatalf("expected legacy document removed, found %d", legacyCount)
	}
}

func TestSetLibraryBookIds_preservesAddedAtForExistingBooks(t *testing.T) {
	db := integrationMongoDB(t)
	const libID, userID = "lib-keep", "user-keep"

	if err := SetLibraryBookIds(db, libID, userID, []string{"keep-me"}); err != nil {
		t.Fatalf("SetLibraryBookIds first: %v", err)
	}
	first, err := GetLibraryBookEntries(db, libID, userID)
	if err != nil || len(first) != 1 {
		t.Fatalf("first read: %v, len=%d", err, len(first))
	}
	keepAt := first[0].AddedAt

	time.Sleep(50 * time.Millisecond)

	if err := SetLibraryBookIds(db, libID, userID, []string{"keep-me", "new-one"}); err != nil {
		t.Fatalf("SetLibraryBookIds second: %v", err)
	}
	second, err := GetLibraryBookEntries(db, libID, userID)
	if err != nil || len(second) != 2 {
		t.Fatalf("second read: %v, len=%d", err, len(second))
	}

	var kept, added *LibraryBookEntry
	for i := range second {
		switch second[i].BookId {
		case "keep-me":
			k := second[i]
			kept = &k
		case "new-one":
			k := second[i]
			added = &k
		}
	}
	if kept == nil || added == nil {
		t.Fatalf("missing entry: kept=%v added=%v", kept, added)
	}
	if !kept.AddedAt.Equal(keepAt) {
		t.Fatalf("addedAt for existing book changed: was %v, now %v", keepAt, kept.AddedAt)
	}
	if added.AddedAt.Before(keepAt) {
		t.Fatalf("new book addedAt %v should not be before kept %v", added.AddedAt, keepAt)
	}
}

func TestSetLibraryBookIds_removesBooksNotInList(t *testing.T) {
	db := integrationMongoDB(t)
	const libID, userID = "lib-del", "user-del"

	if err := SetLibraryBookIds(db, libID, userID, []string{"a", "b", "c"}); err != nil {
		t.Fatalf("SetLibraryBookIds: %v", err)
	}
	if err := SetLibraryBookIds(db, libID, userID, []string{"b"}); err != nil {
		t.Fatalf("SetLibraryBookIds shrink: %v", err)
	}
	entries, err := GetLibraryBookEntries(db, libID, userID)
	if err != nil {
		t.Fatalf("GetLibraryBookEntries: %v", err)
	}
	if len(entries) != 1 || entries[0].BookId != "b" {
		t.Fatalf("expected [b], got %+v", entries)
	}
}

func TestSetLibraryBookIds_deduplicatesInput(t *testing.T) {
	db := integrationMongoDB(t)
	const libID, userID = "lib-dedupe", "user-dedupe"

	if err := SetLibraryBookIds(db, libID, userID, []string{"x", " x ", "x"}); err != nil {
		t.Fatalf("SetLibraryBookIds: %v", err)
	}
	entries, err := GetLibraryBookEntries(db, libID, userID)
	if err != nil {
		t.Fatalf("GetLibraryBookEntries: %v", err)
	}
	if len(entries) != 1 || entries[0].BookId != "x" {
		t.Fatalf("expected one edge for x, got %+v", entries)
	}
}
