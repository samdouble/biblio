package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"

	"tsunbooku-api/books"
	"tsunbooku-api/db"
	"tsunbooku-api/libraries"
	"tsunbooku-api/types"
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
	bookIds := make([]string, len(entries))
	for i, e := range entries {
		bookIds[i] = e.BookId
	}
	summaries, err := books.SummariesByIDs(database, bookIds)
	if err != nil {
		log.Printf("books.SummariesByIDs: %v", err)
		return types.GetLibraryBooksResponse{
			Body: types.GetLibraryBooksResponseBody{Error: "failed to get library books"},
		}, err
	}
	booksJSON := make([]types.LibraryBookEntryJSON, len(entries))
	for i, e := range entries {
		entry := types.LibraryBookEntryJSON{BookId: e.BookId, AddedAt: e.AddedAt.UnixMilli()}
		if summary, ok := summaries[e.BookId]; ok {
			entry.Isbn = summary.ISBN
			entry.Title = summary.Title
			entry.Author = summary.Author
			entry.ThumbnailUrl = summary.ThumbnailURL
		}
		booksJSON[i] = entry
	}

	return types.GetLibraryBooksResponse{
		Body: types.GetLibraryBooksResponseBody{Books: booksJSON},
	}, nil
}
