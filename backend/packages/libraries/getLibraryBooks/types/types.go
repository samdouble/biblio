package types

type GetLibraryBooksEvent struct {
	UserId    string `json:"userId"`
	LibraryId string `json:"libraryId"`
}

type GetLibraryBooksResponseBody struct {
	BookIds []string `json:"bookIds,omitempty"`
	Error   string  `json:"error,omitempty"`
}

type GetLibraryBooksResponse struct {
	Body GetLibraryBooksResponseBody `json:"body"`
}
