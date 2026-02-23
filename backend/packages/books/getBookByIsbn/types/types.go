package types

import (
	"time"
	"biblio-api/types/isbnSearch"
)

type Book struct {
	Id string `json:"id" bson:"id"`
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	Isbn string `json:"isbn" bson:"isbn"`
	SearchId string `json:"searchId" bson:"searchId"`
	VolumeInfo isbnSearch.VolumeInfo `json:"volumeInfo" bson:"volumeInfo"`
}

type Search struct {
    Id string `json:"id" bson:"id"`
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
	Isbn string `json:"isbn" bson:"isbn"`
	Result *IsbnSearchResponse `json:"result,omitempty" bson:"result,omitempty"`
}

type Event struct {
	Isbn string `json:"isbn"`
}

type ResponseBody struct {
	Books []interface{} `json:"books"`
}

type Response struct {
	Body ResponseBody `json:"body"`
}
