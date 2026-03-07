package libraries

import (
	"context"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

const LibraryBooksCollectionName = "library_books"

type LibraryBooksDoc struct {
	LibraryId string   `bson:"libraryId" json:"libraryId"`
	UserId    string   `bson:"userId" json:"userId"`
	BookIds   []string `bson:"bookIds" json:"bookIds"`
}

func GetLibraryBookIds(database *mongo.Database, libraryId, userId string) ([]string, error) {
	coll := database.Collection(LibraryBooksCollectionName)
	var doc LibraryBooksDoc
	err := coll.FindOne(context.TODO(), bson.M{"libraryId": libraryId, "userId": userId}).Decode(&doc)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	if doc.BookIds == nil {
		return []string{}, nil
	}
	return doc.BookIds, nil
}

func SetLibraryBookIds(database *mongo.Database, libraryId, userId string, bookIds []string) error {
	if bookIds == nil {
		bookIds = []string{}
	}
	coll := database.Collection(LibraryBooksCollectionName)
	doc := LibraryBooksDoc{LibraryId: libraryId, UserId: userId, BookIds: bookIds}
	opts := options.Update().SetUpsert(true)
	_, err := coll.UpdateOne(
		context.TODO(),
		bson.M{"libraryId": libraryId, "userId": userId},
		bson.M{"$set": doc},
		opts,
	)
	return err
}
