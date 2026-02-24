package models

import (
	"context"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"biblio-api/types"
	"biblio-api/utils"
)

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
