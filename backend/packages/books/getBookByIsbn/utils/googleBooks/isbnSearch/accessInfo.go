package isbnSearch

type Epub struct {
	IsAvailable bool `json:"isAvailable" bson:"isAvailable"`
}

type Pdf struct {
	IsAvailable bool `json:"isAvailable" bson:"isAvailable"`
}

type AccessInfo struct {
	Country string `json:"country" bson:"country"`
	Viewability string `json:"viewability" bson:"viewability"`
	Embeddable bool `json:"embeddable" bson:"embeddable"`
	PublicDomain bool `json:"publicDomain" bson:"publicDomain"`
	TextToSpeechPermission string `json:"textToSpeechPermission" bson:"textToSpeechPermission"`
	Epub Epub `json:"epub" bson:"epub"`
	Pdf Pdf `json:"pdf" bson:"pdf"`
	AccessViewStatus string `json:"accessViewStatus" bson:"accessViewStatus"`
}
