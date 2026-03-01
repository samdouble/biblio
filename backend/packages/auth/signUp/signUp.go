package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"

	"biblio-api/db"
	"biblio-api/models"
	"biblio-api/types"
)

const bcryptCost = 12

func Main(ctx context.Context, event types.SignUpEvent) (types.SignUpResponse, error) {
	email := strings.TrimSpace(strings.ToLower(event.Email))
	password := event.Password
	name := strings.TrimSpace(event.Name)

	if email == "" {
		return types.SignUpResponse{
			Body: types.SignUpResponseBody{Error: "email is required"},
		}, fmt.Errorf("email is required")
	}
	if password == "" {
		return types.SignUpResponse{
			Body: types.SignUpResponseBody{Error: "password is required"},
		}, fmt.Errorf("password is required")
	}
	if len(password) < 8 {
		return types.SignUpResponse{
			Body: types.SignUpResponseBody{Error: "password must be at least 8 characters"},
		}, fmt.Errorf("password too short")
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	defer db.CloseClientDB()

	database := client.Database(os.Getenv("MONGO_DBNAME"))

	existing, err := models.GetUserByEmail(database, email)
	if err != nil {
		log.Printf("GetUserByEmail: %v", err)
		return types.SignUpResponse{
			Body: types.SignUpResponseBody{Error: "registration failed"},
		}, err
	}
	if existing != nil {
		return types.SignUpResponse{
			Body: types.SignUpResponseBody{Error: "email already registered"},
		}, fmt.Errorf("email already registered")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	if err != nil {
		log.Printf("bcrypt: %v", err)
		return types.SignUpResponse{
			Body: types.SignUpResponseBody{Error: "registration failed"},
		}, err
	}

	user := types.User{
		Id:           uuid.New().String(),
		Email:        email,
		PasswordHash: string(hash),
		Name:         name,
		CreatedAt:    time.Now().UTC(),
	}

	if err := models.InsertUser(database, user); err != nil {
		log.Printf("InsertUser: %v", err)
		return types.SignUpResponse{
			Body: types.SignUpResponseBody{Error: "registration failed"},
		}, err
	}

	return types.SignUpResponse{
		Body: types.SignUpResponseBody{
			UserId: user.Id,
			Email:  user.Email,
		},
	}, nil
}
