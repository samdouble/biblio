package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
	"go.mongodb.org/mongo-driver/v2/mongo/writeconcern"

	"tsundoku-api/authors"
	"tsundoku-api/db"
	"tsundoku-api/models"
	"tsundoku-api/types"
	"tsundoku-api/utils"
	googleBooksApi "tsundoku-api/utils/googleBooks/api"
	isbnDbApi "tsundoku-api/utils/isbnDb/api"
)

func Main(ctx context.Context, event types.GetBookByIsbnEvent) (types.Response, error) {
	if event.Isbn == "" {
		log.Println("ISBN is required")
		return types.Response{}, fmt.Errorf("ISBN is required")
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))

	database := client.Database(os.Getenv("MONGO_DBNAME"))
	searchesCollection := database.Collection("searches")

	wc := writeconcern.Majority()
	transactionOptions := options.Transaction().SetWriteConcern(wc)
	session, err := client.StartSession()
	if err != nil {
		log.Fatal(err)
	}
	defer session.EndSession(context.TODO())

	insertResults, err := session.WithTransaction(context.TODO(), func(ctx context.Context) (interface{}, error) {
		existingBooks, err := models.GetBooksIfIsbnAlreadyExists(database, event.Isbn)
		if err != nil {
			return nil, err
		}
		searchId := uuid.New().String()
		if len(existingBooks) == 0 {
			var books []types.Book
			var search types.Search

			isbnDbResp, err := isbnDbApi.SearchBooksByIsbn(event.Isbn)
			if err == nil && len(isbnDbResp.Data) > 0 {
				fmt.Println("No existing books found. Fetched from ISBNdb.")
				for i := range isbnDbResp.Data {
					b := &isbnDbResp.Data[i]
					vol := utils.IsbnDbBookToVolumeInfo(b)
					books = append(books, types.Book{
						Id:          uuid.New().String(),
						CreatedAt:   time.Now().UTC(),
						Isbn:        event.Isbn,
						SearchId:    searchId,
						VolumeInfo:  vol,
						ApiProvider: "isbndb",
					})
				}
				search = types.Search{
					Id:        searchId,
					CreatedAt: time.Now().UTC(),
					Isbn:      event.Isbn,
					Result:    nil,
				}
			} else {
				if err != nil {
					log.Printf("ISBNdb lookup failed: %v; falling back to Google Books", err)
				}
				fmt.Println("No existing books found. Fetching from Google Books API.")
				googleResp, err := googleBooksApi.SearchBooksByIsbn(event.Isbn)
				if err != nil {
					return nil, err
				}
				search = types.Search{
					Id:        searchId,
					CreatedAt: time.Now().UTC(),
					Isbn:      event.Isbn,
					Result:    googleResp,
				}
				for _, item := range googleResp.Items {
					books = append(books, types.Book{
						Id:          uuid.New().String(),
						CreatedAt:   time.Now().UTC(),
						Isbn:        event.Isbn,
						SearchId:    searchId,
						VolumeInfo:  item.VolumeInfo,
						ApiProvider: "googleBooks",
					})
				}
			}

			if len(books) > 0 {
				_, err = models.InsertSearch(database, search)
				if err != nil {
					return nil, err
				}
				_, err = models.InsertBooks(database, books)
				if err != nil {
					return nil, err
				}
				if err = authors.UpsertNames(database, authorNamesFromBooks(books)); err != nil {
					return nil, err
				}
				return books, nil
			}
			search = types.Search{Id: searchId, CreatedAt: time.Now().UTC(), Isbn: event.Isbn}
			_, _ = models.InsertSearch(database, search)
			return []types.Book{}, nil
		} else {
			fmt.Println(len(existingBooks), "existing book(s) found for ISBN", event.Isbn)
			for _, book := range existingBooks {
				fmt.Println(book.Id, book.VolumeInfo.Title, book.VolumeInfo.Authors)
			}
			search := types.Search{
				Id: searchId,
				CreatedAt: time.Now().UTC(),
				Isbn: event.Isbn,
			}
			_, err = searchesCollection.InsertOne(context.TODO(), search)
			if err != nil {
				return nil, err
			}
			if err = authors.UpsertNames(database, authorNamesFromBooks(existingBooks)); err != nil {
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

func authorNamesFromBooks(books []types.Book) []string {
	var names []string
	for _, book := range books {
		names = append(names, book.VolumeInfo.Authors...)
	}
	return names
}
