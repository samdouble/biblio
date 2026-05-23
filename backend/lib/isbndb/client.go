package isbndb

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"time"
)

const BaseURL = "https://api2.isbndb.com"

type Client struct {
	apiKey     string
	httpClient *http.Client
}

func NewClient() (*Client, error) {
	key := os.Getenv("ISBNDB_API_KEY")
	if key == "" {
		return nil, fmt.Errorf("ISBNDB_API_KEY is not set")
	}
	return &Client{
		apiKey:     key,
		httpClient: &http.Client{Timeout: 30 * time.Second},
	}, nil
}

func (c *Client) FetchAuthorBooks(authorName string, page, pageSize int) (*AuthorBooksResponse, error) {
	encoded := url.PathEscape(authorName)
	params := url.Values{}
	params.Set("page", fmt.Sprintf("%d", page))
	params.Set("pageSize", fmt.Sprintf("%d", pageSize))
	reqURL := fmt.Sprintf("%s/author/%s?%s", BaseURL, encoded, params.Encode())
	return c.getAuthorBooks(reqURL)
}

func (c *Client) FetchUpdatedISBNs(lastUpdated time.Time, page, pageSize int) (*UpdatedFeedResponse, error) {
	params := url.Values{}
	params.Set("page", fmt.Sprintf("%d", page))
	params.Set("pageSize", fmt.Sprintf("%d", pageSize))
	if !lastUpdated.IsZero() {
		params.Set("lastUpdated", lastUpdated.Format("2006-01-02"))
	}
	reqURL := fmt.Sprintf("%s/feeds/updated-book?%s", BaseURL, params.Encode())
	return c.getUpdatedFeed(reqURL)
}

func (c *Client) FetchBooksByISBNs(isbns []string) ([]Book, error) {
	if len(isbns) == 0 {
		return nil, nil
	}
	body, err := json.Marshal(map[string][]string{"isbns": isbns})
	if err != nil {
		return nil, err
	}
	req, err := http.NewRequest(http.MethodPost, BaseURL+"/books", bytes.NewReader(body))
	if err != nil {
		return nil, err
	}
	c.setHeaders(req)
	req.Header.Set("Content-Type", "application/json")

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusTooManyRequests {
		return nil, ErrRateLimit
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("isbndb: unexpected status %d", resp.StatusCode)
	}

	var out BooksResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, err
	}
	return out.Books, nil
}

func (c *Client) getAuthorBooks(reqURL string) (*AuthorBooksResponse, error) {
	req, err := http.NewRequest(http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, err
	}
	c.setHeaders(req)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return &AuthorBooksResponse{Books: nil}, nil
	}
	if resp.StatusCode == http.StatusTooManyRequests {
		return nil, ErrRateLimit
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("isbndb: unexpected status %d", resp.StatusCode)
	}

	var out AuthorBooksResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, err
	}
	return &out, nil
}

func (c *Client) getUpdatedFeed(reqURL string) (*UpdatedFeedResponse, error) {
	req, err := http.NewRequest(http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, err
	}
	c.setHeaders(req)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound || resp.StatusCode == http.StatusForbidden {
		return nil, fmt.Errorf("isbndb: feed unavailable (status %d)", resp.StatusCode)
	}
	if resp.StatusCode == http.StatusTooManyRequests {
		return nil, ErrRateLimit
	}
	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("isbndb: unexpected status %d", resp.StatusCode)
	}

	var out UpdatedFeedResponse
	if err := json.NewDecoder(resp.Body).Decode(&out); err != nil {
		return nil, err
	}
	return &out, nil
}

func (c *Client) setHeaders(req *http.Request) {
	req.Header.Set("Authorization", c.apiKey)
	req.Header.Set("Accept", "application/json")
}
