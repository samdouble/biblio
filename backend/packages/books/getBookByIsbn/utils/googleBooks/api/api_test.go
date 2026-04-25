package api

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSearchBooksByIsbn_ParsesResponse(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte(`{"totalItems":1,"items":[{"id":"x","volumeInfo":{"title":"Go","authors":["A"]}}]}`))
	}))
	defer srv.Close()

	orig := GoogleBooksAPIBaseURL
	GoogleBooksAPIBaseURL = srv.URL
	defer func() { GoogleBooksAPIBaseURL = orig }()

	resp, err := SearchBooksByIsbn("9780000000000")
	if err != nil {
		t.Fatalf("expected nil error, got %v", err)
	}
	if resp.TotalItems != 1 || len(resp.Items) != 1 || resp.Items[0].VolumeInfo.Title != "Go" {
		t.Fatalf("unexpected parsed response: %#v", resp)
	}
}
