package utils

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"net/url"
	"os"
)

const isbnDbBaseURL = "https://api2.isbndb.com"

type IsbnDbBook struct {
	Title         string   `json:"title"`
	TitleLong     string   `json:"titleLong"`
	ISBN          string   `json:"isbn"`
	ISBN13        string   `json:"isbn13"`
	ISBN10        string   `json:"isbn10"`
	Publisher     string   `json:"publisher"`
	Language      string   `json:"language"`
	DatePublished string   `json:"datePublished"`
	Edition       string   `json:"edition"`
	Pages         *int     `json:"pages"`
	Binding       string   `json:"binding"`
	Image         string   `json:"image"`
	Overview      string   `json:"overview"`
	Synopsis      string   `json:"synopsis"`
	Excerpt       string   `json:"excerpt"`
	Authors       []string `json:"authors"`
	Subjects      []string `json:"subjects"`
}

type IsbnDbSearchBooksResponse struct {
	Total    int          `json:"total"`
	Page     int          `json:"page"`
	PageSize int          `json:"pageSize"`
	Data     []IsbnDbBook `json:"-"`
}

func (r *IsbnDbSearchBooksResponse) UnmarshalJSON(b []byte) error {
	var raw struct {
		Total    int          `json:"total"`
		Page     int          `json:"page"`
		PageSize int          `json:"pageSize"`
		Data     []IsbnDbBook `json:"data"`
		Books    []IsbnDbBook `json:"books"`
	}
	if err := json.Unmarshal(b, &raw); err != nil {
		return err
	}
	r.Total = raw.Total
	r.Page = raw.Page
	r.PageSize = raw.PageSize
	if len(raw.Data) > 0 {
		r.Data = raw.Data
	} else {
		r.Data = raw.Books
	}
	return nil
}

func SearchBooksByIsbn(isbn string) (*IsbnDbSearchBooksResponse, error) {
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
		return &IsbnDbSearchBooksResponse{Data: nil}, nil
	}
	if resp.StatusCode == http.StatusTooManyRequests {
		log.Printf("ISBNdb rate limit exceeded (429)")
		return nil, fmt.Errorf("ISBNdb: rate limit exceeded")
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("ISBNdb: unexpected status %d", resp.StatusCode)
	}

	var out IsbnDbSearchBooksResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, err
	}
	return &out, nil
}
