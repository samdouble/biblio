package types

import (
	"encoding/json"
)

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
