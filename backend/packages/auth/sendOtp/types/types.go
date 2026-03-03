package types

type SendOtpEvent struct {
	Email string `json:"email"`
}

type SendOtpResponseBody struct {
	Sent  bool   `json:"sent,omitempty"`
	Error string `json:"error,omitempty"`
}

type SendOtpResponse struct {
	Body SendOtpResponseBody `json:"body"`
}
