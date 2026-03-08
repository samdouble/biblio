package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"

	isbnDbTypes "biblio-api/utils/isbnDb"
)

type GetAuthorBooksResponse struct {
	Author string              `json:"author"`
	Books  []isbnDbTypes.IsbnDbBook `json:"books"`
}

func GetBooksByAuthor(authorName string) (*GetAuthorBooksResponse, error) {
	key := os.Getenv("ISBNDB_API_KEY")
	if key == "" {
		return nil, fmt.Errorf("ISBNDB_API_KEY is not set")
	}
	encoded := url.PathEscape(authorName)
	reqURL := fmt.Sprintf("%s/author/%s", isbnDbBaseURL, encoded)
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
		return &GetAuthorBooksResponse{Author: authorName, Books: nil}, nil
	}
	if resp.StatusCode == http.StatusTooManyRequests {
		return nil, fmt.Errorf("ISBNdb: rate limit exceeded")
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("ISBNdb: unexpected status %d", resp.StatusCode)
	}

	var out GetAuthorBooksResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, err
	}
	return &out, nil
}
