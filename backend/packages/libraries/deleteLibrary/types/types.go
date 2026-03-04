package types

type DeleteLibraryEvent struct {
	UserId    string `json:"userId"`
	LibraryId string `json:"libraryId"`
}

type DeleteLibraryResponseBody struct {
	Error string `json:"error,omitempty"`
}

type DeleteLibraryResponse struct {
	Body DeleteLibraryResponseBody `json:"body"`
}
