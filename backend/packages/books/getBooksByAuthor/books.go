package main

import (
	"context"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

const booksCollection = "books"

// bookDoc matches the "books" collection schema used by getBookByIsbn and searchBooks.
type bookDoc struct {
	Id          string     `bson:"id" json:"id"`
	CreatedAt   time.Time  `bson:"createdAt" json:"createdAt"`
	Isbn        string     `bson:"isbn" json:"isbn"`
	SearchId    string     `bson:"searchId" json:"searchId"`
	VolumeInfo  volumeInfoDoc `bson:"volumeInfo" json:"volumeInfo"`
	ApiProvider string     `bson:"apiProvider" json:"apiProvider"`
}

type volumeInfoDoc struct {
	Title         string            `bson:"title" json:"title"`
	Authors       []string          `bson:"authors" json:"authors"`
	Publisher     string            `bson:"publisher" json:"publisher"`
	PublishedDate string            `bson:"publishedDate" json:"publishedDate"`
	Description   string            `bson:"description" json:"description"`
	PageCount     int               `bson:"pageCount" json:"pageCount"`
	ImageLinks    imageLinksDoc     `bson:"imageLinks" json:"imageLinks"`
}

type imageLinksDoc struct {
	Thumbnail      string `bson:"thumbnail" json:"thumbnail"`
	SmallThumbnail string `bson:"smallThumbnail" json:"smallThumbnail"`
}

func insertAuthorBooks(db *mongo.Database, books []isbnDbBook) ([]string, error) {
	coll := db.Collection(booksCollection)
	isbns := make([]string, 0, len(books))
	for i := range books {
		b := &books[i]
		doc := isbnDbBookToBookDoc(b)
		_, err := coll.InsertOne(context.TODO(), doc)
		if err != nil {
			continue
		}
		isbn := b.ISBN13
		if isbn == "" {
			isbn = b.ISBN
		}
		if isbn != "" {
			isbns = append(isbns, isbn)
		}
	}
	return isbns, nil
}

func isbnDbBookToBookDoc(b *isbnDbBook) bookDoc {
	pageCount := 0
	if b.Pages != nil {
		pageCount = *b.Pages
	}
	authors := b.Authors
	if authors == nil {
		authors = []string{}
	}
	isbn := b.ISBN13
	if isbn == "" {
		isbn = b.ISBN
	}
	return bookDoc{
		Id:          uuid.New().String(),
		CreatedAt:   time.Now().UTC(),
		Isbn:        isbn,
		SearchId:    "",
		ApiProvider: "isbndb",
		VolumeInfo: volumeInfoDoc{
			Title:         b.Title,
			Authors:       authors,
			Publisher:     b.Publisher,
			PublishedDate: b.DatePublished,
			Description:   b.Overview,
			PageCount:     pageCount,
			ImageLinks: imageLinksDoc{
				Thumbnail:      b.Image,
				SmallThumbnail: b.Image,
			},
		},
	}
}

func getBooksByIsbns(db *mongo.Database, isbns []string) ([]interface{}, error) {
	if len(isbns) == 0 {
		return []interface{}{}, nil
	}
	coll := db.Collection(booksCollection)
	cursor, err := coll.Find(context.TODO(), bson.M{"isbn": bson.M{"$in": isbns}})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(context.TODO())

	seen := make(map[string]bool)
	var out []interface{}
	for cursor.Next(context.TODO()) {
		var doc bookDoc
		if err := cursor.Decode(&doc); err != nil {
			continue
		}
		if seen[doc.Isbn] {
			continue
		}
		seen[doc.Isbn] = true
		out = append(out, doc)
	}
	return out, cursor.Err()
}
