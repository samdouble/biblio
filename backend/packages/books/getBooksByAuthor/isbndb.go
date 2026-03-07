package main

type isbnDbBook struct {
	Title         string   `json:"title"`
	ISBN          string   `json:"isbn"`
	ISBN13        string   `json:"isbn13"`
	Publisher     string   `json:"publisher"`
	DatePublished string   `json:"datePublished"`
	Pages         *int     `json:"pages"`
	Image         string   `json:"image"`
	Overview      string   `json:"overview"`
	Synopsis      string   `json:"synopsis"`
	Excerpt       string   `json:"excerpt"`
	Authors       []string `json:"authors"`
}

type isbnDbAuthorResponse struct {
	Author string       `json:"author"`
	Books  []isbnDbBook `json:"books"`
}
