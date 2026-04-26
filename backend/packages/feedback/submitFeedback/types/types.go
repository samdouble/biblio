package types

type SubmitFeedbackEvent struct {
	UserId      string `json:"userId"`
	Type        string `json:"type"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Email       string `json:"email,omitempty"`
}

type FeedbackPayload struct {
	Id          string `json:"id"`
	Type        string `json:"type"`
	Title       string `json:"title"`
	Description string `json:"description"`
	Email       string `json:"email,omitempty"`
	CreatedAt   string `json:"createdAt"`
}

type SubmitFeedbackResponseBody struct {
	Feedback *FeedbackPayload `json:"feedback,omitempty"`
	Error    string           `json:"error,omitempty"`
}

type SubmitFeedbackResponse struct {
	Body SubmitFeedbackResponseBody `json:"body"`
}
