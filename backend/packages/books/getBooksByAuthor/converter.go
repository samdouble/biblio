package main

import (
	"biblio-api/types"
)

func isbnDbBookToOutput(b *isbnDbBook) types.BookOutput {
	pageCount := 0
	if b.Pages != nil {
		pageCount = *b.Pages
	}
	img := types.ImageLinks{}
	if b.Image != "" {
		img.Thumbnail = b.Image
		img.SmallThumbnail = b.Image
	}
	desc := b.Overview
	if desc == "" {
		desc = b.Synopsis
	}
	if desc == "" {
		desc = b.Excerpt
	}
	authors := b.Authors
	if authors == nil {
		authors = []string{}
	}
	id := b.ISBN13
	if id == "" {
		id = b.ISBN
	}
	isbn := b.ISBN
	if isbn == "" {
		isbn = b.ISBN13
	}
	return types.BookOutput{
		Id:   id,
		Isbn: isbn,
		VolumeInfo: types.VolumeInfo{
			Title:         b.Title,
			Authors:       authors,
			Publisher:     b.Publisher,
			PublishedDate: b.DatePublished,
			Description:   desc,
			PageCount:     pageCount,
			ImageLinks:    img,
		},
	}
}
