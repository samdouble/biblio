package types

type SetLibraryBooksEvent struct {
	UserId    string   `json:"userId"`
	LibraryId string   `json:"libraryId"`
	BookIds   []string `json:"bookIds"`
}

type SetLibraryBooksResponseBody struct {
	Error string `json:"error,omitempty"`
}

type SetLibraryBooksResponse struct {
	Body SetLibraryBooksResponseBody `json:"body"`
}
