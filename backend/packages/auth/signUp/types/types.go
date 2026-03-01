package types

import "time"

type SignUpEvent struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	Name     string `json:"name"`
}

type User struct {
	Id           string    `json:"id" bson:"id"`
	Email        string    `json:"email" bson:"email"`
	PasswordHash string    `json:"-" bson:"passwordHash"`
	Name         string    `json:"name" bson:"name"`
	CreatedAt    time.Time `json:"createdAt" bson:"createdAt"`
}

type SignUpResponseBody struct {
	UserId string `json:"userId,omitempty"`
	Email  string `json:"email,omitempty"`
	Error  string `json:"error,omitempty"`
}

type SignUpResponse struct {
	Body SignUpResponseBody `json:"body"`
}
