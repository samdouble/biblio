package main

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"

	"biblio-api/db"
	"biblio-api/models"
	"biblio-api/otps"
	"biblio-api/types"
)

func Main(ctx context.Context, event types.VerifyOtpEvent) (types.VerifyOtpResponse, error) {
	email := strings.TrimSpace(strings.ToLower(event.Email))
	otp := strings.TrimSpace(event.Otp)

	if email == "" {
		return types.VerifyOtpResponse{
			Body: types.VerifyOtpResponseBody{Error: "email is required"},
		}, fmt.Errorf("email is required")
	}
	if otp == "" {
		return types.VerifyOtpResponse{
			Body: types.VerifyOtpResponseBody{Error: "code is required"},
		}, fmt.Errorf("otp is required")
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	rec, err := otps.GetByEmail(database, email)
	if err != nil {
		log.Printf("otps.GetByEmail: %v", err)
		return types.VerifyOtpResponse{
			Body: types.VerifyOtpResponseBody{Error: "invalid or expired code"},
		}, err
	}
	if rec == nil {
		return types.VerifyOtpResponse{
			Body: types.VerifyOtpResponseBody{Error: "invalid or expired code"},
		}, fmt.Errorf("no otp for email")
	}

	if time.Now().UTC().After(rec.ExpiresAt) {
		_ = otps.DeleteByEmail(database, email)
		return types.VerifyOtpResponse{
			Body: types.VerifyOtpResponseBody{Error: "code has expired"},
		}, fmt.Errorf("otp expired")
	}

	otpHash := hashOtp(otp)
	if otpHash != rec.OtpHash {
		return types.VerifyOtpResponse{
			Body: types.VerifyOtpResponseBody{Error: "invalid or expired code"},
		}, fmt.Errorf("invalid otp")
	}

	if err := otps.DeleteByEmail(database, email); err != nil {
		log.Printf("otps.DeleteByEmail: %v", err)
	}

	user, err := models.GetUserByEmail(database, email)
	if err != nil {
		log.Printf("GetUserByEmail: %v", err)
		return types.VerifyOtpResponse{
			Body: types.VerifyOtpResponseBody{Error: "sign-in failed"},
		}, err
	}

	if user == nil {
		user = &types.User{
			Id:        uuid.New().String(),
			Email:     email,
			Name:     "",
			CreatedAt: time.Now().UTC(),
		}
		if err := models.InsertUser(database, *user); err != nil {
			log.Printf("InsertUser: %v", err)
			return types.VerifyOtpResponse{
				Body: types.VerifyOtpResponseBody{Error: "sign-in failed"},
			}, err
		}
	}

	return types.VerifyOtpResponse{
		Body: types.VerifyOtpResponseBody{
			UserId: user.Id,
			Email:  user.Email,
		},
	}, nil
}

func hashOtp(otp string) string {
	h := sha256.Sum256([]byte(otp))
	return hex.EncodeToString(h[:])
}
