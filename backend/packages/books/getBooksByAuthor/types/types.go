package types

type GetBooksByAuthorEvent struct {
	Author string `json:"author"`
}

type BookOutput struct {
	Id         string      `json:"id"`
	Isbn       string      `json:"isbn"`
	VolumeInfo VolumeInfo `json:"volumeInfo"`
}

type VolumeInfo struct {
	Title         string     `json:"title"`
	Authors       []string   `json:"authors"`
	Publisher     string     `json:"publisher"`
	PublishedDate string     `json:"publishedDate"`
	Description   string     `json:"description"`
	PageCount     int        `json:"pageCount"`
	ImageLinks    ImageLinks `json:"imageLinks,omitempty"`
}

type ImageLinks struct {
	Thumbnail      string `json:"thumbnail"`
	SmallThumbnail string `json:"smallThumbnail"`
}

type GetBooksByAuthorResponseBody struct {
	Books []interface{} `json:"books"`
	Error string        `json:"error,omitempty"`
}

type GetBooksByAuthorResponse struct {
	Body GetBooksByAuthorResponseBody `json:"body"`
}
