package utils

import (
	"testing"

	isbnDbTypes "tsunbooku-api/utils/isbnDb"
)

func TestIsbnDbBookToVolumeInfo_UsesOverviewAndImageAndPages(t *testing.T) {
	pages := 321
	in := &isbnDbTypes.IsbnDbBook{
		Title:         "Book",
		ISBN:          "123",
		ISBN13:        "1234567890123",
		Publisher:     "Pub",
		Language:      "en",
		DatePublished: "2024",
		Pages:         &pages,
		Image:         "https://img.example/cover.jpg",
		Overview:      "Overview text",
		Authors:       []string{"Ada"},
		Subjects:      []string{"Computers"},
	}
	out := IsbnDbBookToVolumeInfo(in)
	if out.Title != "Book" || out.PageCount != 321 || out.Description != "Overview text" {
		t.Fatalf("unexpected conversion result: %#v", out)
	}
	if out.ImageLinks.Thumbnail == "" || len(out.IndustryIdentifiers) != 2 {
		t.Fatalf("expected image and both ISBN ids, got %#v", out)
	}
}

func TestIsbnDbBookToVolumeInfo_FallbacksAndDefaults(t *testing.T) {
	in := &isbnDbTypes.IsbnDbBook{
		Title:    "Book",
		Synopsis: "Synopsis text",
	}
	out := IsbnDbBookToVolumeInfo(in)
	if out.Description != "Synopsis text" {
		t.Fatalf("expected synopsis fallback, got %q", out.Description)
	}
	if out.PageCount != 0 || out.Categories == nil {
		t.Fatalf("expected default page count and non-nil categories: %#v", out)
	}
}

