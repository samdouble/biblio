package books

import (
	"context"
	"fmt"
	"hash/fnv"
	"os"
	"testing"
	"time"

	"tsunbooku-api/isbndb"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

func integrationMongoDB(t *testing.T) *mongo.Database {
	t.Helper()
	uri := os.Getenv("MONGO_URL")
	if uri == "" {
		t.Skip("MONGO_URL not set, skipping integration test")
	}
	client, err := mongo.Connect(options.Client().
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
	db := client.Database(fmt.Sprintf("t_books_%08x", h.Sum32()))
	t.Cleanup(func() {
		_ = db.Drop(context.Background())
	})
	return db
}

func TestInsertFromIsbnDb_skipsDuplicates(t *testing.T) {
	db := integrationMongoDB(t)
	pages := 200
	book := isbndb.Book{
		Title:   "Test Book",
		ISBN13:  "978-0000000001",
		Authors: []string{"Test Author"},
		Pages:   &pages,
	}

	inserted, err := InsertFromIsbnDb(db, book)
	if err != nil {
		t.Fatalf("first insert: %v", err)
	}
	if !inserted {
		t.Fatal("expected first insert to succeed")
	}

	inserted, err = InsertFromIsbnDb(db, book)
	if err != nil {
		t.Fatalf("second insert: %v", err)
	}
	if inserted {
		t.Fatal("expected duplicate insert to be skipped")
	}

	ctx := context.Background()
	n, err := db.Collection(CollectionName).CountDocuments(ctx, bson.M{"isbn": "978-0000000001"})
	if err != nil {
		t.Fatalf("CountDocuments: %v", err)
	}
	if n != 1 {
		t.Fatalf("expected 1 book document, got %d", n)
	}
}
