package models

import (
	"context"
	"tsunbooku-api/types"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

func InsertSearch(database *mongo.Database, search types.Search) (*mongo.InsertOneResult, error) {
	searchesCollection := database.Collection("searches")
	_, err := searchesCollection.InsertOne(context.TODO(), search)
	if err != nil {
		return nil, err
	}
	return nil, nil
}
