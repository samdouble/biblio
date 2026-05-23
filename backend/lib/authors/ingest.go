package authors

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

func FindDueForIngest(database *mongo.Database, limit int, staleBefore time.Time) ([]Author, error) {
	if limit <= 0 {
		return nil, nil
	}
	coll := database.Collection(CollectionName)
	filter := bson.M{
		"$or": []bson.M{
			{"lastIngestedAt": bson.M{"$exists": false}},
			{"lastIngestedAt": nil},
			{"lastIngestedAt": bson.M{"$lt": staleBefore}},
		},
	}
	opts := options.Find().
		SetSort(bson.D{{Key: "lastIngestedAt", Value: 1}, {Key: "createdAt", Value: 1}}).
		SetLimit(int64(limit))
	cursor, err := coll.Find(context.TODO(), filter, opts)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(context.TODO())

	var out []Author
	if err := cursor.All(context.TODO(), &out); err != nil {
		return nil, err
	}
	return out, nil
}

func MarkIngested(database *mongo.Database, authorID string, ingestErr error) error {
	if authorID == "" {
		return nil
	}
	now := time.Now().UTC()
	update := bson.M{
		"lastIngestedAt": now,
		"lastIngestError": "",
	}
	if ingestErr != nil {
		update["lastIngestError"] = ingestErr.Error()
	}
	_, err := database.Collection(CollectionName).UpdateOne(
		context.TODO(),
		bson.M{"id": authorID},
		bson.M{"$set": update},
	)
	return err
}
