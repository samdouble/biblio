package isbndb

import (
	"encoding/json"
	"errors"
)

var ErrRateLimit = errors.New("isbndb: rate limit exceeded")

type Book struct {
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

func (b Book) PrimaryISBN() string {
	if b.ISBN13 != "" {
		return b.ISBN13
	}
	return b.ISBN
}

type AuthorBooksResponse struct {
	Author string `json:"author"`
	Books  []Book `json:"books"`
}

type BooksResponse struct {
	Books []Book `json:"-"`
}

func (r *BooksResponse) UnmarshalJSON(b []byte) error {
	var raw struct {
		Data  []Book `json:"data"`
		Books []Book `json:"books"`
	}
	if err := json.Unmarshal(b, &raw); err != nil {
		return err
	}
	if len(raw.Data) > 0 {
		r.Books = raw.Data
	} else {
		r.Books = raw.Books
	}
	return nil
}

type UpdatedISBN struct {
	ISBN13      string `json:"isbn13"`
	ISBN        string `json:"isbn"`
	LastUpdated string `json:"lastUpdated"`
}

func (u UpdatedISBN) PrimaryISBN() string {
	if u.ISBN13 != "" {
		return u.ISBN13
	}
	return u.ISBN
}

type UpdatedFeedResponse struct {
	Updates []UpdatedISBN `json:"-"`
}

func (r *UpdatedFeedResponse) UnmarshalJSON(b []byte) error {
	var raw struct {
		Updates []UpdatedISBN `json:"updates"`
		Data    []UpdatedISBN `json:"data"`
	}
	if err := json.Unmarshal(b, &raw); err != nil {
		return err
	}
	if len(raw.Updates) > 0 {
		r.Updates = raw.Updates
	} else {
		r.Updates = raw.Data
	}
	return nil
}
