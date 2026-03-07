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

func Main(ctx context.Context, event types.SetLibraryBooksEvent) (types.SetLibraryBooksResponse, error) {
	userId := strings.TrimSpace(event.UserId)
	libraryId := strings.TrimSpace(event.LibraryId)

	if userId == "" || libraryId == "" {
		return types.SetLibraryBooksResponse{
			Body: types.SetLibraryBooksResponseBody{Error: "userId and libraryId are required"},
		}, fmt.Errorf("userId and libraryId are required")
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	// Ensure the library belongs to the user
	lib, err := libraries.GetByIdAndUserId(database, libraryId, userId)
	if err != nil {
		log.Printf("libraries.GetByIdAndUserId: %v", err)
		return types.SetLibraryBooksResponse{
			Body: types.SetLibraryBooksResponseBody{Error: "failed to get library"},
		}, err
	}
	if lib == nil {
		return types.SetLibraryBooksResponse{
			Body: types.SetLibraryBooksResponseBody{Error: "library not found"},
		}, nil
	}

	if err := libraries.SetLibraryBookIds(database, libraryId, userId, event.BookIds); err != nil {
		log.Printf("libraries.SetLibraryBookIds: %v", err)
		return types.SetLibraryBooksResponse{
			Body: types.SetLibraryBooksResponseBody{Error: "failed to set library books"},
		}, err
	}

	return types.SetLibraryBooksResponse{Body: types.SetLibraryBooksResponseBody{}}, nil
}
