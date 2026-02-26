package utils

import (
	"biblio-api/utils/googleBooks/isbnSearch"
	isbnDbTypes "biblio-api/utils/isbnDb"
)

func IsbnDbBookToVolumeInfo(b *isbnDbTypes.IsbnDbBook) isbnSearch.VolumeInfo {
	pageCount := 0
	if b.Pages != nil {
		pageCount = *b.Pages
	}
	industryIDs := []isbnSearch.IndustryIdentifier{}
	if b.ISBN13 != "" {
		industryIDs = append(industryIDs, isbnSearch.IndustryIdentifier{Type: "ISBN_13", Identifier: b.ISBN13})
	}
	if b.ISBN != "" {
		industryIDs = append(industryIDs, isbnSearch.IndustryIdentifier{Type: "ISBN_10", Identifier: b.ISBN})
	}
	img := isbnSearch.ImageLinks{}
	if b.Image != "" {
		img.Thumbnail = b.Image
		img.Small = b.Image
		img.Medium = b.Image
		img.Large = b.Image
	}
	desc := b.Overview
	if desc == "" {
		desc = b.Synopsis
	}
	if desc == "" {
		desc = b.Excerpt
	}
	categories := b.Subjects
	if categories == nil {
		categories = []string{}
	}
	return isbnSearch.VolumeInfo{
		Title:            b.Title,
		Authors:          b.Authors,
		Publisher:        b.Publisher,
		PublishedDate:    b.DatePublished,
		Description:      desc,
		IndustryIdentifiers: industryIDs,
		PageCount:        pageCount,
		Categories:       categories,
		ImageLinks:       img,
		Language:         b.Language,
	}
}
