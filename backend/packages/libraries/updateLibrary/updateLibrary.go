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

func Main(ctx context.Context, event types.UpdateLibraryEvent) (types.UpdateLibraryResponse, error) {
	userId := strings.TrimSpace(event.UserId)
	libraryId := strings.TrimSpace(event.LibraryId)
	name := strings.TrimSpace(event.Name)

	if userId == "" {
		return types.UpdateLibraryResponse{
			Body: types.UpdateLibraryResponseBody{Error: "user id is required"},
		}, fmt.Errorf("user id is required")
	}
	if libraryId == "" {
		return types.UpdateLibraryResponse{
			Body: types.UpdateLibraryResponseBody{Error: "library id is required"},
		}, fmt.Errorf("library id is required")
	}
	if name == "" {
		return types.UpdateLibraryResponse{
			Body: types.UpdateLibraryResponseBody{Error: "name is required"},
		}, fmt.Errorf("name is required")
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	defer db.CloseClientDB()
	database := client.Database(os.Getenv("MONGO_DBNAME"))

	lib, err := libraries.GetByIdAndUserId(database, libraryId, userId)
	if err != nil {
		log.Printf("libraries.GetByIdAndUserId: %v", err)
		return types.UpdateLibraryResponse{
			Body: types.UpdateLibraryResponseBody{Error: "failed to update library"},
		}, err
	}
	if lib == nil {
		return types.UpdateLibraryResponse{
			Body: types.UpdateLibraryResponseBody{Error: "library not found"},
		}, fmt.Errorf("library not found")
	}

	if err := libraries.UpdateName(database, libraryId, userId, name); err != nil {
		log.Printf("libraries.UpdateName: %v", err)
		return types.UpdateLibraryResponse{
			Body: types.UpdateLibraryResponseBody{Error: "failed to update library"},
		}, err
	}

	return types.UpdateLibraryResponse{Body: types.UpdateLibraryResponseBody{}}, nil
}
