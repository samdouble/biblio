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
	"biblio-api/libraries"
	"biblio-api/types"
)

func Main(ctx context.Context, event types.CreateLibraryEvent) (types.CreateLibraryResponse, error) {
	userId := strings.TrimSpace(event.UserId)
	name := strings.TrimSpace(event.Name)

	if userId == "" {
		return types.CreateLibraryResponse{
			Body: types.CreateLibraryResponseBody{Error: "user id is required"},
		}, fmt.Errorf("user id is required")
	}
	if name == "" {
		return types.CreateLibraryResponse{
			Body: types.CreateLibraryResponseBody{Error: "name is required"},
		}, fmt.Errorf("name is required")
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	defer db.CloseClientDB()
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	now := time.Now().UTC()
	lib := libraries.Library{
		Id:        uuid.New().String(),
		UserId:    userId,
		Name:      name,
		CreatedAt: now,
	}
	if err := libraries.Insert(database, lib); err != nil {
		log.Printf("libraries.Insert: %v", err)
		return types.CreateLibraryResponse{
			Body: types.CreateLibraryResponseBody{Error: "failed to create library"},
		}, err
	}

	return types.CreateLibraryResponse{
		Body: types.CreateLibraryResponseBody{
			Library: &types.LibraryPayload{
				Id:        lib.Id,
				Name:      lib.Name,
				CreatedAt: now.Format(time.RFC3339),
			},
		},
	}, nil
}
