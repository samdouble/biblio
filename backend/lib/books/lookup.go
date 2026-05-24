package books

import (
	"context"
	"strings"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
)

type Summary struct {
	ID           string
	ISBN         string
	Title        string
	Author       string
	ThumbnailURL string
}

func SummariesByIDs(database *mongo.Database, ids []string) (map[string]Summary, error) {
	unique := make([]string, 0, len(ids))
	seen := make(map[string]struct{}, len(ids))
	for _, id := range ids {
		id = strings.TrimSpace(id)
		if id == "" {
			continue
		}
		if _, ok := seen[id]; ok {
			continue
		}
		seen[id] = struct{}{}
		unique = append(unique, id)
	}
	if len(unique) == 0 {
		return map[string]Summary{}, nil
	}

	cursor, err := database.Collection(CollectionName).Find(
		context.TODO(),
		bson.M{"id": bson.M{"$in": unique}},
	)
	if err != nil {
		return nil, err
	}
	defer cursor.Close(context.TODO())

	out := make(map[string]Summary, len(unique))
	for cursor.Next(context.TODO()) {
		var doc bookDoc
		if err := cursor.Decode(&doc); err != nil {
			return nil, err
		}
		id := strings.TrimSpace(doc.Id)
		if id == "" {
			continue
		}
		author := ""
		if len(doc.VolumeInfo.Authors) > 0 {
			author = doc.VolumeInfo.Authors[0]
		}
		thumb := doc.VolumeInfo.ImageLinks.Thumbnail
		if thumb == "" {
			thumb = doc.VolumeInfo.ImageLinks.SmallThumbnail
		}
		out[id] = Summary{
			ID:           id,
			ISBN:         doc.Isbn,
			Title:        doc.VolumeInfo.Title,
			Author:       author,
			ThumbnailURL: thumb,
		}
	}
	if err := cursor.Err(); err != nil {
		return nil, err
	}
	return out, nil
}
