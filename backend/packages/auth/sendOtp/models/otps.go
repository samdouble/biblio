package models

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

const otpsCollectionName = "otps"
const otpExpiryMinutes = 10

type OtpRecord struct {
	Email     string    `bson:"email"`
	OtpHash   string    `bson:"otpHash"`
	ExpiresAt time.Time `bson:"expiresAt"`
}

func UpsertOtp(database *mongo.Database, email, otpHash string) error {
	coll := database.Collection(otpsCollectionName)
	expiresAt := time.Now().UTC().Add(otpExpiryMinutes * time.Minute)
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

func GetOtpByEmail(database *mongo.Database, email string) (*OtpRecord, error) {
	coll := database.Collection(otpsCollectionName)
	var rec OtpRecord
	err := coll.FindOne(context.TODO(), bson.M{"email": email}).Decode(&rec)
	if err != nil {
		if err == mongo.ErrNoDocuments {
			return nil, nil
		}
		return nil, err
	}
	return &rec, nil
}

func DeleteOtpByEmail(database *mongo.Database, email string) error {
	coll := database.Collection(otpsCollectionName)
	_, err := coll.DeleteOne(context.TODO(), bson.M{"email": email})
	return err
}
