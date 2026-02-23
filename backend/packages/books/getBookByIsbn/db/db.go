package db

import (
    "context"
    "fmt"
    "go.mongodb.org/mongo-driver/mongo"
    "go.mongodb.org/mongo-driver/mongo/options"
    "log"
)

var client *mongo.Client

func ResolveClientDB(url string) *mongo.Client {
    if client != nil {
        return client
    }

    var err error
    clientOptions := options.Client().ApplyURI(url)
    client, err = mongo.Connect(context.TODO(), clientOptions)
    if err != nil {
        log.Fatal(err)
    }

    err = client.Ping(context.TODO(), nil)
    if err != nil {
        log.Fatal(err)
    }

	fmt.Println("Connected to MongoDB")
    return client
}

func CloseClientDB() {
    if client == nil {
        return
    }

    err := client.Disconnect(context.TODO())
    if err != nil {
        log.Fatal(err)
    }

    fmt.Println("Disconnected from MongoDB.")
}
