package api

import (
	"fmt"
	"net/http"
	"os"
	"log"
	"encoding/json"
	"biblio-api/types"
)

var GoogleBooksAPIBaseURL = "https://www.googleapis.com/books/v1/volumes"

func SearchBooksByIsbn(isbn string) (*types.IsbnSearchResponse, error) {
	response, err := http.Get(
		fmt.Sprintf(
			"%s?q=isbn:%s&key=%s",
			GoogleBooksAPIBaseURL,
			isbn,
			os.Getenv("GOOGLE_BOOKS_API_TOKEN"),
		),
	)
	if err != nil {
		log.Fatal(err)
	}
	isbnSearchResponse := &types.IsbnSearchResponse{}
	json.NewDecoder(response.Body).Decode(isbnSearchResponse)
	return isbnSearchResponse, nil
}
