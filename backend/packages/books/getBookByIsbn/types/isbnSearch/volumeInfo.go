package isbnSearch

type Dimensions struct {
	Height string `json:"height" bson:"height"`
	Width string `json:"width" bson:"width"`
	Thickness string `json:"thickness" bson:"thickness"`
}

type ImageLinks struct {
	SmallThumbnail string `json:"smallThumbnail" bson:"smallThumbnail"`
	Thumbnail string `json:"thumbnail" bson:"thumbnail"`
	Small string `json:"small" bson:"small"`
	Medium string `json:"medium" bson:"medium"`
	Large string `json:"large" bson:"large"`
	ExtraLarge string `json:"extraLarge" bson:"extraLarge"`
}

type IndustryIdentifier struct {
	Type string `json:"type" bson:"type"`
	Identifier string `json:"identifier" bson:"identifier"`
}

type VolumeInfo struct {
	Title string `json:"title" bson:"title"`
	Authors []string `json:"authors" bson:"authors"`
	Publisher string `json:"publisher" bson:"publisher"`
	PublishedDate string `json:"publishedDate" bson:"publishedDate"`
	Description string `json:"description" bson:"description"`
	IndustryIdentifiers []IndustryIdentifier `json:"industryIdentifiers" bson:"industryIdentifiers"`
	PageCount int `json:"pageCount" bson:"pageCount"`
	Dimensions Dimensions `json:"dimensions" bson:"dimensions"`
	PrintType string `json:"printType" bson:"printType"`
	MainCategory string `json:"mainCategory" bson:"mainCategory"`
	Categories []string `json:"categories" bson:"categories"`
	AverageRating float64 `json:"averageRating" bson:"averageRating"`
	RatingsCount int `json:"ratingsCount" bson:"ratingsCount"`
	ContentVersion string `json:"contentVersion" bson:"contentVersion"`
	ImageLinks ImageLinks `json:"imageLinks" bson:"imageLinks"`
	Language string `json:"language" bson:"language"`
	InfoLink string `json:"infoLink" bson:"infoLink"`
	CanonicalVolumeLink string `json:"canonicalVolumeLink" bson:"canonicalVolumeLink"`
}
