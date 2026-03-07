package main

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"os"
	"strings"

	"biblio-api/db"
	"biblio-api/otps"
	"biblio-api/ses"
	"biblio-api/types"
)

const otpDigits = 6

func Main(ctx context.Context, event types.SendOtpEvent) (types.SendOtpResponse, error) {
	email := strings.TrimSpace(strings.ToLower(event.Email))
	if email == "" {
		return types.SendOtpResponse{
			Body: types.SendOtpResponseBody{Error: "email is required"},
		}, fmt.Errorf("email is required")
	}

	otpCode, err := generateOtp(otpDigits)
	if err != nil {
		log.Printf("generateOtp: %v", err)
		return types.SendOtpResponse{
			Body: types.SendOtpResponseBody{Error: "failed to send code"},
		}, err
	}

	otpHash := hashOtp(otpCode)

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	if err := otps.Upsert(database, email, otpHash); err != nil {
		log.Printf("otps.Upsert: %v", err)
		return types.SendOtpResponse{
			Body: types.SendOtpResponseBody{Error: "failed to send code"},
		}, err
	}

	region := "us-east-1"
	if err := ses.SendOtpEmail(ctx, email, otpCode, region); err != nil {
		log.Printf("SendOtpEmail: %v", err)
		return types.SendOtpResponse{
			Body: types.SendOtpResponseBody{Error: "failed to send code"},
		}, err
	}

	return types.SendOtpResponse{
		Body: types.SendOtpResponseBody{Sent: true},
	}, nil
}

func generateOtp(digits int) (string, error) {
	const digitspace = "0123456789"
	b := make([]byte, digits)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	for i := range b {
		b[i] = digitspace[int(b[i])%len(digitspace)]
	}
	return string(b), nil
}

func hashOtp(otp string) string {
	h := sha256.Sum256([]byte(otp))
	return hex.EncodeToString(h[:])
}
