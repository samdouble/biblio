package main

import (
	"context"
	"encoding/json"
	"log"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, _ events.CloudWatchEvent) error {
	result, err := Main(ctx)
	if err != nil {
		log.Printf("ingestCatalog failed: %v", err)
		return err
	}
	b, _ := json.Marshal(result)
	log.Printf("ingestCatalog completed: %s", string(b))
	return nil
}

func main() {
	lambda.Start(handler)
}
