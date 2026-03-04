package types

type UpdateLibraryEvent struct {
	UserId    string `json:"userId"`
	LibraryId string `json:"libraryId"`
	Name      string `json:"name"`
}

type UpdateLibraryResponseBody struct {
	Error string `json:"error,omitempty"`
}

type UpdateLibraryResponse struct {
	Body UpdateLibraryResponseBody `json:"body"`
}
