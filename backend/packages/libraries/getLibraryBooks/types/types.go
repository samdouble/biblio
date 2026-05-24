package types

type GetLibraryBooksEvent struct {
	UserId    string `json:"userId"`
	LibraryId string `json:"libraryId"`
}

type LibraryBookEntryJSON struct {
	BookId       string `json:"bookId"`
	AddedAt      int64  `json:"addedAt"`
	Isbn         string `json:"isbn,omitempty"`
	Title        string `json:"title,omitempty"`
	Author       string `json:"author,omitempty"`
	ThumbnailUrl string `json:"thumbnailUrl,omitempty"`
}

type GetLibraryBooksResponseBody struct {
	Books []LibraryBookEntryJSON `json:"books,omitempty"`
	Error string                 `json:"error,omitempty"`
}

type GetLibraryBooksResponse struct {
	Body GetLibraryBooksResponseBody `json:"body"`
}
