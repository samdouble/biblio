package testutil

import (
	"context"
	"fmt"
	"hash/fnv"
	"os"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
)

func SetupIntegrationMongo(t *testing.T, namePrefix string) {
	t.Helper()
	uri := os.Getenv("MONGO_URL")
	if uri == "" {
		t.Skip("MONGO_URL not set, skipping integration test")
	}
	h := fnv.New32a()
	_, _ = h.Write([]byte(t.Name()))
	dbName := fmt.Sprintf("t_%s_%08x", namePrefix, h.Sum32())
	t.Setenv("MONGO_URL", uri)
	t.Setenv("MONGO_DBNAME", dbName)
	t.Cleanup(func() {
		ctx := context.Background()
		c, err := mongo.Connect(options.Client().
			ApplyURI(uri).
			SetConnectTimeout(5*time.Second).
			SetServerSelectionTimeout(5*time.Second))
		if err != nil {
			return
		}
		defer func() { _ = c.Disconnect(ctx) }()
		_ = c.Database(dbName).Drop(ctx)
	})
}
