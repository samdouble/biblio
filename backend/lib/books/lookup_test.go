package books

import (
	"context"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

func TestSummariesByIDs_returnsMetadataForKnownBooks(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	client, err := mongo.Connect(options.Client().ApplyURI("mongodb://localhost:27017").SetConnectTimeout(2 * time.Second))
	if err != nil {
		t.Skipf("mongo not available: %v", err)
	}
	t.Cleanup(func() { _ = client.Disconnect(context.Background()) })

	if err := client.Ping(ctx, nil); err != nil {
		t.Skipf("mongo not available: %v", err)
	}

	db := client.Database("books_lookup_test")
	coll := db.Collection(CollectionName)
	_ = coll.Drop(ctx)

	_, err = coll.InsertOne(ctx, bson.M{
		"id":        "book-1",
		"createdAt": time.Now().UTC(),
		"isbn":      "9780000000001",
		"volumeInfo": bson.M{
			"title":   "Test Title",
			"authors": []string{"Test Author"},
			"imageLinks": bson.M{
				"thumbnail": "https://example.com/thumb.jpg",
			},
		},
	})
	if err != nil {
		t.Skipf("mongo not available: %v", err)
	}

	summaries, err := SummariesByIDs(db, []string{"book-1", "missing"})
	if err != nil {
		t.Fatalf("SummariesByIDs: %v", err)
	}
	if len(summaries) != 1 {
		t.Fatalf("expected 1 summary, got %d", len(summaries))
	}
	s := summaries["book-1"]
	if s.ISBN != "9780000000001" || s.Title != "Test Title" || s.Author != "Test Author" {
		t.Fatalf("unexpected summary: %+v", s)
	}
	if s.ThumbnailURL != "https://example.com/thumb.jpg" {
		t.Fatalf("unexpected thumbnail: %q", s.ThumbnailURL)
	}
}
