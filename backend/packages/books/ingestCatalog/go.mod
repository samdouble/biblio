module tsunbooku-api

go 1.25

replace (
	tsunbooku-api/authors => ../../../lib/authors
	tsunbooku-api/books => ../../../lib/books
	tsunbooku-api/db => ../../../lib/db
	tsunbooku-api/ingest => ../../../lib/ingest
	tsunbooku-api/isbndb => ../../../lib/isbndb
)

require (
	github.com/aws/aws-lambda-go v1.54.0
	tsunbooku-api/db v0.0.0
	tsunbooku-api/ingest v0.0.0
	tsunbooku-api/isbndb v0.0.0
)

require (
	github.com/google/uuid v1.6.0 // indirect
	github.com/klauspost/compress v1.17.6 // indirect
	github.com/xdg-go/pbkdf2 v1.0.0 // indirect
	github.com/xdg-go/scram v1.2.0 // indirect
	github.com/xdg-go/stringprep v1.0.4 // indirect
	github.com/youmark/pkcs8 v0.0.0-20240726163527-a2c0da244d78 // indirect
	go.mongodb.org/mongo-driver/v2 v2.7.0 // indirect
	golang.org/x/crypto v0.33.0 // indirect
	golang.org/x/sync v0.11.0 // indirect
	golang.org/x/text v0.22.0 // indirect
	tsunbooku-api/authors v0.0.0 // indirect
	tsunbooku-api/books v0.0.0 // indirect
)
