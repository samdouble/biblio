package types

type CreateLibraryEvent struct {
	UserId string `json:"userId"`
	Name   string `json:"name"`
}

type LibraryPayload struct {
	Id        string `json:"id"`
	Name      string `json:"name"`
	CreatedAt string `json:"createdAt"`
}

type CreateLibraryResponseBody struct {
	Library *LibraryPayload `json:"library,omitempty"`
	Error   string         `json:"error,omitempty"`
}

type CreateLibraryResponse struct {
	Body CreateLibraryResponseBody `json:"body"`
}
