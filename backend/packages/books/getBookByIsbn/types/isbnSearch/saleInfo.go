package isbnSearch

type ListPrice struct {
	Amount float64 `json:"amount" bson:"amount"`
	CurrencyCode string `json:"currencyCode" bson:"currencyCode"`
}

type RentPrice struct {
	Amount float64 `json:"amount" bson:"amount"`
	CurrencyCode string `json:"currencyCode" bson:"currencyCode"`
}

type SaleInfo struct {
	Country string `json:"country" bson:"country"`
	IsEbook bool `json:"isEbook" bson:"isEbook"`
	Saleability string `json:"saleability" bson:"saleability"`
	ListPrice ListPrice `json:"listPrice" bson:"listPrice"`
	RentPrice RentPrice `json:"rentPrice" bson:"rentPrice"`
	BuyLink string `json:"buyLink" bson:"buyLink"`
}
