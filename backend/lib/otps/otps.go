package otps

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

const CollectionName = "otps"
const ExpiryMinutes = 10

type Record struct {
	Email     string    `bson:"email"`
	OtpHash   string    `bson:"otpHash"`
	ExpiresAt time.Time `bson:"expiresAt"`
}

func Upsert(database *mongo.Database, email, otpHash string) error {
	coll := database.Collection(CollectionName)
	expiresAt := time.Now().UTC().Add(ExpiryMinutes * time.Minute)
	doc := bson.M{
		"email":     email,
		"otpHash":   otpHash,
		"expiresAt": expiresAt,
	}
	opts := options.Update().SetUpsert(true)
	_, err := coll.UpdateOne(
		context.TODO(),
		bson.M{"email": email},
		bson.M{"$set": doc},
		opts,
	)
	return err
}

func GetByEmail(database *mongo.Database, email string) (*Record, error) {
	coll := database.Collection(CollectionName)
	var rec Record
	err := coll.FindOne(context.TODO(), bson.M{"email": email}).Decode(&rec)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	return &rec, nil
}

func DeleteByEmail(database *mongo.Database, email string) error {
	coll := database.Collection(CollectionName)
	_, err := coll.DeleteOne(context.TODO(), bson.M{"email": email})
	return err
}
