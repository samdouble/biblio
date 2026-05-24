package models_test

import (
	"os"
	"testing"
	"time"

	"tsundoku-api/db"
	"tsundoku-api/models"
	"tsundoku-api/testutil"
	"tsundoku-api/types"
)

func TestGetUserByEmail_notFound(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "models")
	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	u, err := models.GetUserByEmail(database, "missing@example.com")
	if err != nil {
		t.Fatalf("GetUserByEmail: %v", err)
	}
	if u != nil {
		t.Fatalf("expected nil user, got %+v", u)
	}
}

func TestInsertUser_andGetUserByEmail(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "models")
	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	now := time.Now().UTC().Truncate(time.Millisecond)
	user := types.User{
		Id:        "id-models-1",
		Email:     "found@example.com",
		Name:      "Sam",
		CreatedAt: now,
	}
	if err := models.InsertUser(database, user); err != nil {
		t.Fatalf("InsertUser: %v", err)
	}
	got, err := models.GetUserByEmail(database, "found@example.com")
	if err != nil {
		t.Fatalf("GetUserByEmail: %v", err)
	}
	if got == nil {
		t.Fatal("expected user")
	}
	if got.Id != user.Id || got.Email != user.Email || got.Name != user.Name {
		t.Fatalf("unexpected user %+v", got)
	}
}
