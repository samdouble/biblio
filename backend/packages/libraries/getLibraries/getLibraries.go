package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"biblio-api/db"
	"biblio-api/libraries"
	"biblio-api/types"
)

func Main(ctx context.Context, event types.GetLibrariesEvent) (types.GetLibrariesResponse, error) {
	userId := strings.TrimSpace(event.UserId)

	if userId == "" {
		return types.GetLibrariesResponse{
			Body: types.GetLibrariesResponseBody{Error: "user id is required"},
		}, fmt.Errorf("user id is required")
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	defer db.CloseClientDB()
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	list, err := libraries.GetByUserId(database, userId)
	if err != nil {
		log.Printf("libraries.GetByUserId: %v", err)
		return types.GetLibrariesResponse{
			Body: types.GetLibrariesResponseBody{Error: "failed to list libraries"},
		}, err
	}

	out := make([]types.LibraryPayload, 0, len(list))
	for _, lib := range list {
		out = append(out, types.LibraryPayload{
			Id:        lib.Id,
			Name:      lib.Name,
			CreatedAt: lib.CreatedAt.Format(time.RFC3339),
		})
	}

	return types.GetLibrariesResponse{
		Body: types.GetLibrariesResponseBody{Libraries: out},
	}, nil
}
