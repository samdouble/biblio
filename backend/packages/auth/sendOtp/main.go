package main

import (
	"context"
	"encoding/json"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"

	"biblio-api/types"
)

func handler(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	var event types.SendOtpEvent
	if req.Body != "" {
		_ = json.Unmarshal([]byte(req.Body), &event)
	}
	resp, err := Main(ctx, event)
	return jsonResponse(resp, err)
}

func jsonResponse(body interface{}, err error) (events.APIGatewayV2HTTPResponse, error) {
	headers := map[string]string{"Content-Type": "application/json", "X-Lambda-Handler": "AuthSendOtp"}
	if err != nil {
		b, _ := json.Marshal(map[string]interface{}{"body": map[string]string{"error": err.Error()}})
		return events.APIGatewayV2HTTPResponse{
			StatusCode: 500,
			Headers:    headers,
			Body:       string(b),
		}, nil
	}
	b, _ := json.Marshal(body)
	return events.APIGatewayV2HTTPResponse{
		StatusCode: 200,
		Headers:    headers,
		Body:       string(b),
	}, nil
}

func main() {
	lambda.Start(handler)
}
