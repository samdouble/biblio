package main

import (
	"context"
	"fmt"
    "log"
	"os"
	"time"
    "github.com/google/uuid"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"go.mongodb.org/mongo-driver/mongo/writeconcern"
	"biblio-api/models"
	"biblio-api/db"
	"biblio-api/types"
)

func Main(ctx context.Context, event types.Event) (types.Response, error) {
	// if event.Isbn == "" {
	// 	log.Println("ISBN is required")
	// 	return nil, fmt.Errorf("ISBN is required")
	// }

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	defer db.CloseClientDB()

	database := client.Database(os.Getenv("MONGO_DBNAME"))
	searchesCollection := database.Collection("searches")

	wc := writeconcern.Majority()
	transactionOptions := options.Transaction().SetWriteConcern(wc)
	session, err := client.StartSession()
	if err != nil {
		log.Fatal(err)
	}
	defer session.EndSession(context.TODO())

	insertResults, err := session.WithTransaction(context.TODO(), func(ctx mongo.SessionContext) (interface{}, error) {
		existingBooks, err := models.GetBooksIfIsbnAlreadyExists(database, event.Isbn)
		if err != nil {
			return nil, err
		}
		searchId := uuid.New().String()
		if len(existingBooks) == 0 {
			fmt.Println("No existing books found. Fetching from Google Books API.")
			isbnSearchResponse, err := models.SearchBooksByIsbnFromGoogle(event.Isbn)
			if err != nil {
				return nil, err
			}
			search := types.Search{
				Id: searchId,
				CreatedAt: time.Now().UTC(),
				Isbn: event.Isbn,
				Result: isbnSearchResponse,
			}
			var books []types.Book
			for _, searchItem := range search.Result.Items {
				books = append(
					books,
					types.Book{
						Id: uuid.New().String(),
						CreatedAt: time.Now().UTC(),
						Isbn: event.Isbn,
						SearchId: searchId,
						VolumeInfo: searchItem.VolumeInfo,
					},
				)
			}
			_, err = searchesCollection.InsertOne(context.TODO(), search)
			if err != nil {
				return nil, err
			}
			_, err = models.InsertBooks(database, books)
			if err != nil {
				return nil, err
			}
			return books, nil
		} else {
			fmt.Println(len(existingBooks), "existing books found.")
			search := types.Search{
				Id: searchId,
				CreatedAt: time.Now().UTC(),
				Isbn: event.Isbn,
			}
			_, err = searchesCollection.InsertOne(context.TODO(), search)
			if err != nil {
				return nil, err
			}
			return existingBooks, nil
		}
	}, transactionOptions)
	if err != nil {
		log.Fatal(err)
	}

	books := insertResults.([]types.Book)
	var booksInterface []interface{}
    for _, book := range books {
        booksInterface = append(booksInterface, book)
    }
	return types.Response {
		Body: types.ResponseBody{
			Books: booksInterface,
		},
	}, nil
}
