package main

import (
	"context"
	"os"

	"tsunbooku-api/db"
	"tsunbooku-api/ingest"
	"tsunbooku-api/isbndb"
)

func Main(ctx context.Context) (ingest.Result, error) {
	client, err := isbndb.NewClient()
	if err != nil {
		return ingest.Result{}, err
	}
	database := db.ResolveClientDB(os.Getenv("MONGO_URL")).Database(os.Getenv("MONGO_DBNAME"))
	cfg := ingest.ConfigFromEnv()
	return ingest.Run(ctx, database, client, cfg)
}
