package types

type GetLibraryBooksEvent struct {
	UserId    string `json:"userId"`
	LibraryId string `json:"libraryId"`
}

type LibraryBookEntryJSON struct {
	BookId  string `json:"bookId"`
	AddedAt int64  `json:"addedAt"`
}

type GetLibraryBooksResponseBody struct {
	Books []LibraryBookEntryJSON `json:"books,omitempty"`
	Error string                 `json:"error,omitempty"`
}

type GetLibraryBooksResponse struct {
	Body GetLibraryBooksResponseBody `json:"body"`
}
