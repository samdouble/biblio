package authors

import (
	"context"
	"fmt"
	"hash/fnv"
	"os"
	"testing"
	"time"

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
	db := client.Database(fmt.Sprintf("t_authors_%08x", h.Sum32()))
	t.Cleanup(func() {
		_ = db.Drop(context.Background())
	})
	return db
}

func TestUpsertNames_createsOneDocumentPerAuthor(t *testing.T) {
	db := integrationMongoDB(t)

	err := UpsertNames(db, []string{"Alice Munro", " Alice Munro ", "Bob Dylan"})
	if err != nil {
		t.Fatalf("UpsertNames: %v", err)
	}

	ctx := context.Background()
	n, err := db.Collection(CollectionName).CountDocuments(ctx, bson.M{})
	if err != nil {
		t.Fatalf("CountDocuments: %v", err)
	}
	if n != 2 {
		t.Fatalf("expected 2 author documents, got %d", n)
	}

	alice, err := GetByName(db, "Alice Munro")
	if err != nil {
		t.Fatalf("GetByName alice: %v", err)
	}
	if alice == nil || alice.Id == "" || alice.Name != "Alice Munro" || alice.CreatedAt.IsZero() {
		t.Fatalf("unexpected alice document: %+v", alice)
	}

	bob, err := GetByName(db, "Bob Dylan")
	if err != nil {
		t.Fatalf("GetByName bob: %v", err)
	}
	if bob == nil || bob.Name != "Bob Dylan" {
		t.Fatalf("unexpected bob document: %+v", bob)
	}
}

func TestUpsertNames_isIdempotent(t *testing.T) {
	db := integrationMongoDB(t)

	if err := UpsertNames(db, []string{"Jane Austen"}); err != nil {
		t.Fatalf("first UpsertNames: %v", err)
	}
	first, err := GetByName(db, "Jane Austen")
	if err != nil {
		t.Fatalf("GetByName: %v", err)
	}

	if err := UpsertNames(db, []string{"Jane Austen"}); err != nil {
		t.Fatalf("second UpsertNames: %v", err)
	}
	second, err := GetByName(db, "Jane Austen")
	if err != nil {
		t.Fatalf("GetByName after second upsert: %v", err)
	}

	ctx := context.Background()
	n, err := db.Collection(CollectionName).CountDocuments(ctx, bson.M{})
	if err != nil {
		t.Fatalf("CountDocuments: %v", err)
	}
	if n != 1 {
		t.Fatalf("expected 1 author document, got %d", n)
	}
	if first.Id != second.Id {
		t.Fatalf("expected same author id on re-upsert, got %q then %q", first.Id, second.Id)
	}
}

func TestUpsertNames_ignoresEmptyNames(t *testing.T) {
	db := integrationMongoDB(t)

	if err := UpsertNames(db, []string{"", "   "}); err != nil {
		t.Fatalf("UpsertNames: %v", err)
	}

	ctx := context.Background()
	n, err := db.Collection(CollectionName).CountDocuments(ctx, bson.M{})
	if err != nil {
		t.Fatalf("CountDocuments: %v", err)
	}
	if n != 0 {
		t.Fatalf("expected 0 author documents, got %d", n)
	}
}
