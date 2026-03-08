package main

import (
	"context"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// Reuse the same "searches" collection. Author cache docs have author/isbns/createdAt
// (ISBN docs have isbn/result). Only ISBNs are stored; book data lives in "books".
const searchesCollection = "searches"
const cacheTTL = 7 * 24 * time.Hour

type authorSearchDoc struct {
	Author    string   `bson:"author"`
	Isbns     []string `bson:"isbns"`
	CreatedAt time.Time `bson:"createdAt"`
}

func normalizeAuthor(author string) string {
	return strings.TrimSpace(author)
}

// getCachedIsbns returns the list of ISBNs for an author if cached and not expired.
func getCachedIsbns(db *mongo.Database, author string) ([]string, bool, error) {
	key := normalizeAuthor(author)
	if key == "" {
		return nil, false, nil
	}
	coll := db.Collection(searchesCollection)
	var doc authorSearchDoc
	err := coll.FindOne(context.TODO(), bson.M{"author": key}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, false, nil
		}
		return nil, false, err
	}
	if time.Since(doc.CreatedAt) > cacheTTL {
		return nil, false, nil
	}
	if doc.Isbns == nil {
		return []string{}, true, nil
	}
	return doc.Isbns, true, nil
}

func setCachedIsbns(db *mongo.Database, author string, isbns []string) error {
	key := normalizeAuthor(author)
	if key == "" {
		return nil
	}
	coll := db.Collection(searchesCollection)
	doc := authorSearchDoc{Author: key, Isbns: isbns, CreatedAt: time.Now()}
	_, err := coll.UpdateOne(
		context.TODO(),
		bson.M{"author": key},
		bson.M{"$set": doc},
		options.Update().SetUpsert(true),
	)
	return err
}
