package books

import (
	"context"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"

	"tsundoku-api/authors"
	"tsundoku-api/isbndb"
)

const CollectionName = "books"

type volumeInfoDoc struct {
	Title         string        `bson:"title"`
	Authors       []string      `bson:"authors"`
	Publisher     string        `bson:"publisher"`
	PublishedDate string        `bson:"publishedDate"`
	Description   string        `bson:"description"`
	PageCount     int           `bson:"pageCount"`
	ImageLinks    imageLinksDoc `bson:"imageLinks"`
}

type imageLinksDoc struct {
	Thumbnail      string `bson:"thumbnail"`
	SmallThumbnail string `bson:"smallThumbnail"`
}

type bookDoc struct {
	Id          string        `bson:"id"`
	CreatedAt   time.Time     `bson:"createdAt"`
	Isbn        string        `bson:"isbn"`
	SearchId    string        `bson:"searchId"`
	VolumeInfo  volumeInfoDoc `bson:"volumeInfo"`
	ApiProvider string        `bson:"apiProvider"`
}

func ExistsByISBN(database *mongo.Database, isbn string) (bool, error) {
	if isbn == "" {
		return false, nil
	}
	coll := database.Collection(CollectionName)
	n, err := coll.CountDocuments(context.TODO(), bson.M{"isbn": isbn})
	if err != nil {
		return false, err
	}
	return n > 0, nil
}

func InsertFromIsbnDb(database *mongo.Database, book isbndb.Book) (inserted bool, err error) {
	isbn := book.PrimaryISBN()
	if isbn == "" {
		return false, nil
	}
	exists, err := ExistsByISBN(database, isbn)
	if err != nil {
		return false, err
	}
	if exists {
		return false, nil
	}

	doc := toBookDoc(book)
	_, err = database.Collection(CollectionName).InsertOne(context.TODO(), doc)
	if err != nil {
		return false, err
	}
	return true, nil
}

func InsertManyFromIsbnDb(database *mongo.Database, books []isbndb.Book) (inserted int, authorNames []string, err error) {
	for i := range books {
		ok, err := InsertFromIsbnDb(database, books[i])
		if err != nil {
			return inserted, authorNames, err
		}
		if ok {
			inserted++
			authorNames = append(authorNames, books[i].Authors...)
		}
	}
	if len(authorNames) > 0 {
		if err := authors.UpsertNames(database, authorNames); err != nil {
			return inserted, authorNames, err
		}
	}
	return inserted, authorNames, nil
}

func toBookDoc(book isbndb.Book) bookDoc {
	pageCount := 0
	if book.Pages != nil {
		pageCount = *book.Pages
	}
	bookAuthors := book.Authors
	if bookAuthors == nil {
		bookAuthors = []string{}
	}
	return bookDoc{
		Id:          uuid.New().String(),
		CreatedAt:   time.Now().UTC(),
		Isbn:        book.PrimaryISBN(),
		SearchId:    "",
		ApiProvider: "isbndb",
		VolumeInfo: volumeInfoDoc{
			Title:         book.Title,
			Authors:       bookAuthors,
			Publisher:     book.Publisher,
			PublishedDate: book.DatePublished,
			Description:   book.Overview,
			PageCount:     pageCount,
			ImageLinks: imageLinksDoc{
				Thumbnail:      book.Image,
				SmallThumbnail: book.Image,
			},
		},
	}
}
