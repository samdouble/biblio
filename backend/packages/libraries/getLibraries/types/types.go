package types

type GetLibrariesEvent struct {
	UserId string `json:"userId"`
}

type LibraryPayload struct {
	Id        string `json:"id"`
	Name      string `json:"name"`
	CreatedAt string `json:"createdAt"`
}

type GetLibrariesResponseBody struct {
	Libraries []LibraryPayload `json:"libraries,omitempty"`
	Error     string           `json:"error,omitempty"`
}

type GetLibrariesResponse struct {
	Body GetLibrariesResponseBody `json:"body"`
}
