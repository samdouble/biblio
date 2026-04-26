package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/google/uuid"

	"biblio-api/db"
	"biblio-api/feedback"
	"biblio-api/types"
)

func Main(ctx context.Context, event types.SubmitFeedbackEvent) (types.SubmitFeedbackResponse, error) {
	userId := strings.TrimSpace(event.UserId)
	feedbackType := strings.ToLower(strings.TrimSpace(event.Type))
	title := strings.TrimSpace(event.Title)
	description := strings.TrimSpace(event.Description)
	email := strings.TrimSpace(event.Email)

	if userId == "" {
		return types.SubmitFeedbackResponse{
			Body: types.SubmitFeedbackResponseBody{Error: "user id is required"},
		}, fmt.Errorf("user id is required")
	}
	if feedbackType == "" {
		return types.SubmitFeedbackResponse{
			Body: types.SubmitFeedbackResponseBody{Error: "type is required"},
		}, fmt.Errorf("type is required")
	}
	if feedbackType != string(feedback.TypeFeature) && feedbackType != string(feedback.TypeBug) {
		return types.SubmitFeedbackResponse{
			Body: types.SubmitFeedbackResponseBody{Error: "type must be either 'feature' or 'bug'"},
		}, fmt.Errorf("type must be either 'feature' or 'bug'")
	}
	if title == "" {
		return types.SubmitFeedbackResponse{
			Body: types.SubmitFeedbackResponseBody{Error: "title is required"},
		}, fmt.Errorf("title is required")
	}
	if description == "" {
		return types.SubmitFeedbackResponse{
			Body: types.SubmitFeedbackResponseBody{Error: "description is required"},
		}, fmt.Errorf("description is required")
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	now := time.Now().UTC()
	record := feedback.Feedback{
		Id:          uuid.New().String(),
		UserId:      userId,
		Type:        feedback.Type(feedbackType),
		Title:       title,
		Description: description,
		Email:       email,
		CreatedAt:   now,
	}
	if err := feedback.Insert(database, record); err != nil {
		log.Printf("feedback.Insert: %v", err)
		return types.SubmitFeedbackResponse{
			Body: types.SubmitFeedbackResponseBody{Error: "failed to submit feedback"},
		}, err
	}

	return types.SubmitFeedbackResponse{
		Body: types.SubmitFeedbackResponseBody{
			Feedback: &types.FeedbackPayload{
				Id:          record.Id,
				Type:        string(record.Type),
				Title:       record.Title,
				Description: record.Description,
				Email:       record.Email,
				CreatedAt:   now.Format(time.RFC3339),
			},
		},
	}, nil
}
