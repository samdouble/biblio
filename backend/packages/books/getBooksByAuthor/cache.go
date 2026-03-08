package main

import (
	"context"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

const searchesCollection = "searches"
const cacheTTL = 7 * 24 * time.Hour

type authorSearchDoc struct {
	Author    string      `bson:"author"`
	Books     interface{} `bson:"books"`
	CreatedAt time.Time   `bson:"createdAt"`
}

func normalizeAuthor(author string) string {
	return strings.TrimSpace(author)
}

func getCachedBooks(db *mongo.Database, author string) (interface{}, bool, error) {
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
	return doc.Books, true, nil
}

func setCachedBooks(db *mongo.Database, author string, books interface{}) error {
	key := normalizeAuthor(author)
	if key == "" {
		return nil
	}
	coll := db.Collection(searchesCollection)
	doc := authorSearchDoc{Author: key, Books: books, CreatedAt: time.Now()}
	_, err := coll.UpdateOne(
		context.TODO(),
		bson.M{"author": key},
		bson.M{"$set": doc},
		options.Update().SetUpsert(true),
	)
	return err
}
