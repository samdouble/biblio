package feedback

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/v2/mongo"
)

const CollectionName = "feedback"

type Type string

const (
	TypeFeature Type = "feature"
	TypeBug     Type = "bug"
)

type Feedback struct {
	Id          string    `bson:"id" json:"id"`
	UserId      string    `bson:"userId" json:"userId"`
	Type        Type      `bson:"type" json:"type"`
	Title       string    `bson:"title" json:"title"`
	Description string    `bson:"description" json:"description"`
	Email       string    `bson:"email,omitempty" json:"email,omitempty"`
	CreatedAt   time.Time `bson:"createdAt" json:"createdAt"`
}

func Insert(database *mongo.Database, value Feedback) error {
	coll := database.Collection(CollectionName)
	_, err := coll.InsertOne(context.TODO(), value)
	return err
}
