package api

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	googleBooksTypes "biblio-api/utils/googleBooks"
)

var GoogleBooksAPIBaseURL = "https://www.googleapis.com/books/v1/volumes"

func SearchBooksByIsbn(isbn string) (*googleBooksTypes.IsbnSearchResponse, error) {
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
	isbnSearchResponse := &googleBooksTypes.IsbnSearchResponse{}
	json.NewDecoder(response.Body).Decode(isbnSearchResponse)
	return isbnSearchResponse, nil
}
