package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
)

const isbnDbBaseURL = "https://api2.isbndb.com"

const authorPageSize = 100

func fetchBooksByAuthorFromIsbnDb(authorName string) (*isbnDbAuthorResponse, error) {
	key := os.Getenv("ISBNDB_API_KEY")
	if key == "" {
		return nil, fmt.Errorf("ISBNDB_API_KEY is not set")
	}
	encoded := url.PathEscape(authorName)
	var allBooks []isbnDbBook
	for page := 1; ; page++ {
		params := url.Values{}
		params.Set("page", fmt.Sprintf("%d", page))
		params.Set("pageSize", fmt.Sprintf("%d", authorPageSize))
		reqURL := fmt.Sprintf("%s/author/%s?%s", isbnDbBaseURL, encoded, params.Encode())
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

		if resp.StatusCode == http.StatusNotFound {
			resp.Body.Close()
			return &isbnDbAuthorResponse{Author: authorName, Books: allBooks}, nil
		}
		if resp.StatusCode == http.StatusTooManyRequests {
			resp.Body.Close()
			return nil, fmt.Errorf("ISBNdb: rate limit exceeded")
		}
		if resp.StatusCode != http.StatusOK {
			resp.Body.Close()
			return nil, fmt.Errorf("ISBNdb: unexpected status %d", resp.StatusCode)
		}

		var out isbnDbAuthorResponse
		if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
			resp.Body.Close()
			return nil, err
		}
		resp.Body.Close()

		allBooks = append(allBooks, out.Books...)
		if len(out.Books) < authorPageSize {
			break
		}
	}
	return &isbnDbAuthorResponse{Author: authorName, Books: allBooks}, nil
}
