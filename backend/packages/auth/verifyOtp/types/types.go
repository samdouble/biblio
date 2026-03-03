package types

import "time"

type VerifyOtpEvent struct {
	Email string `json:"email"`
	Otp   string `json:"otp"`
}

type User struct {
	Id        string    `json:"id" bson:"id"`
	Email     string    `json:"email" bson:"email"`
	Name      string    `json:"name" bson:"name"`
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
}

type VerifyOtpResponseBody struct {
	UserId string `json:"userId,omitempty"`
	Email  string `json:"email,omitempty"`
	Error  string `json:"error,omitempty"`
}

type VerifyOtpResponse struct {
	Body VerifyOtpResponseBody `json:"body"`
}
