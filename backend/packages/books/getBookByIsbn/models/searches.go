package models

import (
	"context"
	"biblio-api/types"
	"go.mongodb.org/mongo-driver/mongo"
)

func InsertSearch(database *mongo.Database, search types.Search) (*mongo.InsertOneResult, error) {
	searchesCollection := database.Collection("searches")
	_, err := searchesCollection.InsertOne(context.TODO(), search)
	if err != nil {
		return nil, err
	}
	return nil, nil
}
