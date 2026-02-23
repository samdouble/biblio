package types

import (
	"biblio-api/types/isbnSearch"
)

type Item struct {
	AccessInfo isbnSearch.AccessInfo `json:"accessInfo"`
	Etag string `json:"etag"`
	GoogleBooksId string `json:"id"`
	SaleInfo isbnSearch.SaleInfo `json:"saleInfo"`
	SelfLink string `json:"selfLink"`
	VolumeInfo isbnSearch.VolumeInfo `json:"volumeInfo"`
}

type IsbnSearchResponse struct {
    Items []Item `json:"items"`
    Kind string `json:"kind"`
	TotalItems int `json:"totalItems"`
}
