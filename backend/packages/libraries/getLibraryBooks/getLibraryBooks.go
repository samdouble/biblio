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

func Main(ctx context.Context, event types.GetLibraryBooksEvent) (types.GetLibraryBooksResponse, error) {
	userId := strings.TrimSpace(event.UserId)
	libraryId := strings.TrimSpace(event.LibraryId)

	if userId == "" || libraryId == "" {
		return types.GetLibraryBooksResponse{
			Body: types.GetLibraryBooksResponseBody{Error: "userId and libraryId are required"},
		}, fmt.Errorf("userId and libraryId are required")
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	// Ensure the library belongs to the user
	lib, err := libraries.GetByIdAndUserId(database, libraryId, userId)
	if err != nil {
		log.Printf("libraries.GetByIdAndUserId: %v", err)
		return types.GetLibraryBooksResponse{
			Body: types.GetLibraryBooksResponseBody{Error: "failed to get library"},
		}, err
	}
	if lib == nil {
		return types.GetLibraryBooksResponse{
			Body: types.GetLibraryBooksResponseBody{Error: "library not found"},
		}, nil
	}

	bookIds, err := libraries.GetLibraryBookIds(database, libraryId, userId)
	if err != nil {
		log.Printf("libraries.GetLibraryBookIds: %v", err)
		return types.GetLibraryBooksResponse{
			Body: types.GetLibraryBooksResponseBody{Error: "failed to get library books"},
		}, err
	}
	if bookIds == nil {
		bookIds = []string{}
	}

	return types.GetLibraryBooksResponse{
		Body: types.GetLibraryBooksResponseBody{BookIds: bookIds},
	}, nil
}
