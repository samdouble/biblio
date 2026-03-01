package models

import (
	"context"

	"biblio-api/types"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

const usersCollectionName = "users"

func GetUserByEmail(database *mongo.Database, email string) (*types.User, error) {
	coll := database.Collection(usersCollectionName)
	var user types.User
	err := coll.FindOne(context.TODO(), bson.M{"email": email}).Decode(&user)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	return &user, nil
}

func InsertUser(database *mongo.Database, user types.User) error {
	coll := database.Collection(usersCollectionName)
	_, err := coll.InsertOne(context.TODO(), user)
	return err
}
