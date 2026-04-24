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

	entries, err := libraries.GetLibraryBookEntries(database, libraryId, userId)
	if err != nil {
		log.Printf("libraries.GetLibraryBookEntries: %v", err)
		return types.GetLibraryBooksResponse{
			Body: types.GetLibraryBooksResponseBody{Error: "failed to get library books"},
		}, err
	}
	books := make([]types.LibraryBookEntryJSON, len(entries))
	for i, e := range entries {
		books[i] = types.LibraryBookEntryJSON{BookId: e.BookId, AddedAt: e.AddedAt.UnixMilli()}
	}

	return types.GetLibraryBooksResponse{
		Body: types.GetLibraryBooksResponseBody{Books: books},
	}, nil
}
