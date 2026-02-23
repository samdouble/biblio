package models

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"biblio-api/types"
	"biblio-api/utils"
)

var GoogleBooksAPIBaseURL = "https://www.googleapis.com/books/v1/volumes"

func SearchBooksByIsbnFromGoogle(isbn string) (*types.IsbnSearchResponse, error) {
	response, err := http.Get(
		fmt.Sprintf(
			"%s?q=isbn:%s&key=%s",
			GoogleBooksAPIBaseURL,
			isbn,
			os.Getenv("GOOGLE_BOOKS_API_TOKEN"),
		),
	)
	if err != nil {
		log.Fatal(err)
	}
	isbnSearchResponse := &types.IsbnSearchResponse{}
	json.NewDecoder(response.Body).Decode(isbnSearchResponse)
	return isbnSearchResponse, nil
}

func GetBooksIfIsbnAlreadyExists(database *mongo.Database, isbn string) ([]types.Book, error) {
	booksCollection := database.Collection("books")
	cursor, err := booksCollection.Find(context.TODO(), bson.M{"isbn": isbn})
	if err != nil {
		return nil, err
	}
	var existingBooks []types.Book
	if err = cursor.All(context.TODO(), &existingBooks); err != nil {
		return nil, err
	}
	return existingBooks, nil
}

func InsertBooks(database *mongo.Database, books []types.Book) (*mongo.InsertManyResult, error) {
	booksCollection := database.Collection("books")
	if len(books) > 0 {
		booksInsertResult, err := booksCollection.InsertMany(context.TODO(), utils.ConvertToInterface(books))
		if err != nil {
			return nil, err
		}
		return booksInsertResult, nil
	}
	return nil, nil
}
