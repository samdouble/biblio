package models

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

const otpsCollectionName = "otps"

type OtpRecord struct {
	Email     string    `bson:"email"`
	OtpHash   string    `bson:"otpHash"`
	ExpiresAt time.Time `bson:"expiresAt"`
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
