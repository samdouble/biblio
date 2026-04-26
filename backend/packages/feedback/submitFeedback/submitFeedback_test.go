package main

import (
	"context"
	"os"
	"testing"
	"time"

	"biblio-api/db"
	"biblio-api/testutil"
	"biblio-api/types"

	"go.mongodb.org/mongo-driver/v2/bson"
)

func TestMain_Validation(t *testing.T) {
	ctx := context.Background()

	cases := []struct {
		name    string
		event   types.SubmitFeedbackEvent
		wantErr string
	}{
		{
			name:    "missing userId",
			event:   types.SubmitFeedbackEvent{Type: "feature", Title: "T", Description: "D"},
			wantErr: "user id is required",
		},
		{
			name:    "missing type",
			event:   types.SubmitFeedbackEvent{UserId: "u1", Title: "T", Description: "D"},
			wantErr: "type is required",
		},
		{
			name:    "invalid type",
			event:   types.SubmitFeedbackEvent{UserId: "u1", Type: "other", Title: "T", Description: "D"},
			wantErr: "type must be either 'feature' or 'bug'",
		},
		{
			name:    "missing title",
			event:   types.SubmitFeedbackEvent{UserId: "u1", Type: "feature", Description: "D"},
			wantErr: "title is required",
		},
		{
			name:    "missing description",
			event:   types.SubmitFeedbackEvent{UserId: "u1", Type: "feature", Title: "T"},
			wantErr: "description is required",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			resp, err := Main(ctx, tc.event)
			if err == nil {
				t.Fatal("expected validation error")
			}
			if resp.Body.Error != tc.wantErr {
				t.Fatalf("expected %q, got %q", tc.wantErr, resp.Body.Error)
			}
			if resp.Body.Feedback != nil {
				t.Fatal("feedback should be nil on error")
			}
		})
	}
}

func TestMain_SubmitsFeedback(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "submitfeedback")
	ctx := context.Background()

	resp, err := Main(ctx, types.SubmitFeedbackEvent{
		UserId:      "user-42",
		Type:        "FEATURE",
		Title:       "Dark mode for stats",
		Description: "Please add a stats page with dark mode support.",
		Email:       "user@example.com",
	})
	if err != nil {
		t.Fatalf("Main: %v", err)
	}
	if resp.Body.Error != "" {
		t.Fatalf("unexpected response error: %q", resp.Body.Error)
	}
	if resp.Body.Feedback == nil {
		t.Fatal("expected feedback payload")
	}

	item := resp.Body.Feedback
	if item.Id == "" {
		t.Fatal("expected generated id")
	}
	if item.Type != "feature" {
		t.Fatalf("expected normalized type 'feature', got %q", item.Type)
	}
	if item.Title != "Dark mode for stats" {
		t.Fatalf("unexpected title: %q", item.Title)
	}
	if item.Description == "" || item.Email != "user@example.com" {
		t.Fatalf("unexpected payload: %+v", item)
	}
	if _, err := time.Parse(time.RFC3339, item.CreatedAt); err != nil {
		t.Fatalf("createdAt should be RFC3339: %q", item.CreatedAt)
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))
	coll := database.Collection("feedback")

	var stored struct {
		Id          string    `bson:"id"`
		UserId      string    `bson:"userId"`
		Type        string    `bson:"type"`
		Title       string    `bson:"title"`
		Description string    `bson:"description"`
		Email       string    `bson:"email"`
		CreatedAt   time.Time `bson:"createdAt"`
	}
	if err := coll.FindOne(context.Background(), bson.M{"id": item.Id}).Decode(&stored); err != nil {
		t.Fatalf("FindOne: %v", err)
	}
	if stored.UserId != "user-42" || stored.Type != "feature" {
		t.Fatalf("unexpected stored identity/type: %+v", stored)
	}
	if stored.Title != item.Title || stored.Description != item.Description || stored.Email != item.Email {
		t.Fatalf("stored data mismatch: %+v", stored)
	}
}
