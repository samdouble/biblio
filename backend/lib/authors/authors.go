package authors

import (
	"context"
	"strings"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

const CollectionName = "authors"

type Author struct {
	Id              string     `bson:"id" json:"id"`
	Name            string     `bson:"name" json:"name"`
	CreatedAt       time.Time  `bson:"createdAt" json:"createdAt"`
	LastIngestedAt  *time.Time `bson:"lastIngestedAt,omitempty" json:"lastIngestedAt,omitempty"`
	LastIngestError string     `bson:"lastIngestError,omitempty" json:"lastIngestError,omitempty"`
}

func NormalizeName(name string) string {
	return strings.TrimSpace(name)
}

func uniqueNames(names []string) []string {
	seen := make(map[string]bool, len(names))
	out := make([]string, 0, len(names))
	for _, raw := range names {
		name := NormalizeName(raw)
		if name == "" || seen[name] {
			continue
		}
		seen[name] = true
		out = append(out, name)
	}
	return out
}

func UpsertNames(database *mongo.Database, names []string) error {
	for _, name := range uniqueNames(names) {
		if err := upsertName(database, name); err != nil {
			return err
		}
	}
	return nil
}

func upsertName(database *mongo.Database, name string) error {
	coll := database.Collection(CollectionName)
	now := time.Now().UTC()
	_, err := coll.UpdateOne(
		context.TODO(),
		bson.M{"name": name},
		bson.M{"$setOnInsert": bson.M{
			"id":        uuid.New().String(),
			"name":      name,
			"createdAt": now,
		}},
		options.UpdateOne().SetUpsert(true),
	)
	return err
}

func GetByName(database *mongo.Database, name string) (*Author, error) {
	key := NormalizeName(name)
	if key == "" {
		return nil, nil
	}
	coll := database.Collection(CollectionName)
	var author Author
	err := coll.FindOne(context.TODO(), bson.M{"name": key}).Decode(&author)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	return &author, nil
}
