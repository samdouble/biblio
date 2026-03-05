package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"

	"biblio-api/db"
	"biblio-api/libraries"
	"biblio-api/types"
)

func Main(ctx context.Context, event types.DeleteLibraryEvent) (types.DeleteLibraryResponse, error) {
	userId := strings.TrimSpace(event.UserId)
	libraryId := strings.TrimSpace(event.LibraryId)

	if userId == "" {
		return types.DeleteLibraryResponse{
			Body: types.DeleteLibraryResponseBody{Error: "user id is required"},
		}, fmt.Errorf("user id is required")
	}
	if libraryId == "" {
		return types.DeleteLibraryResponse{
			Body: types.DeleteLibraryResponseBody{Error: "library id is required"},
		}, fmt.Errorf("library id is required")
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	if err := libraries.Delete(database, libraryId, userId); err != nil {
		log.Printf("libraries.Delete: %v", err)
		return types.DeleteLibraryResponse{
			Body: types.DeleteLibraryResponseBody{Error: "failed to delete library"},
		}, err
	}

	return types.DeleteLibraryResponse{Body: types.DeleteLibraryResponseBody{}}, nil
}
