package api

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"

	isbnDbTypes "biblio-api/utils/isbnDb"
)

const isbnDbBaseURL = "https://api2.isbndb.com"

func SearchBooksByIsbn(isbn string) (*isbnDbTypes.IsbnDbSearchBooksResponse, error) {
	key := os.Getenv("ISBNDB_API_KEY")
	if key == "" {
		return nil, fmt.Errorf("ISBNDB_API_KEY is not set")
	}

	params := url.Values{}
	if len(isbn) == 13 {
		params.Set("isbn13", isbn)
	} else {
		params.Set("isbn", isbn)
	}
	params.Set("pageSize", "20")

	reqURL := fmt.Sprintf("%s/search/books?%s", isbnDbBaseURL, params.Encode())
	req, err := http.NewRequest(http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", key)
	req.Header.Set("Accept", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return &isbnDbTypes.IsbnDbSearchBooksResponse{Data: nil}, nil
	}
	if resp.StatusCode == http.StatusTooManyRequests {
		log.Printf("ISBNdb rate limit exceeded (429)")
		return nil, fmt.Errorf("ISBNdb: rate limit exceeded")
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("ISBNdb: unexpected status %d", resp.StatusCode)
	}

	var out isbnDbTypes.IsbnDbSearchBooksResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, err
	}
	return &out, nil
}
