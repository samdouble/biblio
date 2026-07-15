module tsunbooku-api

go 1.25

replace tsunbooku-api/db => ../../../lib/db

replace tsunbooku-api/auth => ../../../lib/auth

replace tsunbooku-api/libraries => ../../../lib/libraries

replace tsunbooku-api/testutil => ../../../internal/testutil

require (
	github.com/aws/aws-lambda-go v1.54.0
	github.com/google/uuid v1.6.0
	tsunbooku-api/auth v0.0.0
	tsunbooku-api/db v0.0.0
	tsunbooku-api/libraries v0.0.0
	tsunbooku-api/testutil v0.0.0
)

require (
	github.com/golang-jwt/jwt/v5 v5.3.1 // indirect
	github.com/klauspost/compress v1.17.6 // indirect
	github.com/xdg-go/pbkdf2 v1.0.0 // indirect
	github.com/xdg-go/scram v1.2.0 // indirect
	github.com/xdg-go/stringprep v1.0.4 // indirect
	github.com/youmark/pkcs8 v0.0.0-20240726163527-a2c0da244d78 // indirect
	go.mongodb.org/mongo-driver/v2 v2.8.0 // indirect
	golang.org/x/crypto v0.33.0 // indirect
	golang.org/x/sync v0.11.0 // indirect
	golang.org/x/text v0.22.0 // indirect
)
