package types

import "time"

type SearchBooksEvent struct {
	Query string `json:"query"`
	Limit int    `json:"limit"`
}

type Book struct {
	Id          string    `json:"id" bson:"id"`
	CreatedAt   time.Time `json:"createdAt" bson:"createdAt"`
	Isbn        string    `json:"isbn" bson:"isbn"`
	SearchId    string    `json:"searchId" bson:"searchId"`
	VolumeInfo  VolumeInfo `json:"volumeInfo" bson:"volumeInfo"`
	ApiProvider string    `json:"apiProvider" bson:"apiProvider"`
}

type VolumeInfo struct {
	Title         string   `json:"title" bson:"title"`
	Authors       []string `json:"authors" bson:"authors"`
	Publisher     string   `json:"publisher" bson:"publisher"`
	PublishedDate string   `json:"publishedDate" bson:"publishedDate"`
	Description   string   `json:"description" bson:"description"`
	PageCount     int      `json:"pageCount" bson:"pageCount"`
	ImageLinks    ImageLinks `json:"imageLinks" bson:"imageLinks"`
}

type ImageLinks struct {
	SmallThumbnail string `json:"smallThumbnail" bson:"smallThumbnail"`
	Thumbnail      string `json:"thumbnail" bson:"thumbnail"`
	Small          string `json:"small" bson:"small"`
	Medium         string `json:"medium" bson:"medium"`
	Large          string `json:"large" bson:"large"`
	ExtraLarge     string `json:"extraLarge" bson:"extraLarge"`
}

type SearchBooksResponseBody struct {
	Books []interface{} `json:"books"`
	Error string        `json:"error,omitempty"`
}

type SearchBooksResponse struct {
	Body SearchBooksResponseBody `json:"body"`
}
