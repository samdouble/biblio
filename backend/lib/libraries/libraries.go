package libraries

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

const CollectionName = "libraries"

type Library struct {
	Id        string    `bson:"id" json:"id"`
	UserId    string    `bson:"userId" json:"userId"`
	Name      string    `bson:"name" json:"name"`
	CreatedAt time.Time `bson:"createdAt" json:"createdAt"`
}

func Insert(database *mongo.Database, lib Library) error {
	coll := database.Collection(CollectionName)
	_, err := coll.InsertOne(context.TODO(), lib)
	return err
}

func GetByUserId(database *mongo.Database, userId string) ([]Library, error) {
	coll := database.Collection(CollectionName)
	cursor, err := coll.Find(context.TODO(), bson.M{"userId": userId})
	if err != nil {
		return nil, err
	}
	defer cursor.Close(context.TODO())
	var out []Library
	if err := cursor.All(context.TODO(), &out); err != nil {
		return nil, err
	}
	return out, nil
}

func GetByIdAndUserId(database *mongo.Database, id, userId string) (*Library, error) {
	coll := database.Collection(CollectionName)
	var lib Library
	err := coll.FindOne(context.TODO(), bson.M{"id": id, "userId": userId}).Decode(&lib)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	return &lib, nil
}

func UpdateName(database *mongo.Database, id, userId, name string) error {
	coll := database.Collection(CollectionName)
	_, err := coll.UpdateOne(
		context.TODO(),
		bson.M{"id": id, "userId": userId},
		bson.M{"$set": bson.M{"name": name}},
	)
	return err
}

func Delete(database *mongo.Database, id, userId string) error {
	coll := database.Collection(CollectionName)
	_, err := coll.DeleteOne(context.TODO(), bson.M{"id": id, "userId": userId})
	return err
}
