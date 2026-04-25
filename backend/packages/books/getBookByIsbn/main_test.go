package main

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"testing"

	"github.com/aws/aws-lambda-go/events"

	"biblio-api/types"
)

func TestMain_EmptyIsbnReturnsError(t *testing.T) {
	_, err := Main(context.Background(), types.GetBookByIsbnEvent{Isbn: ""})
	if err == nil {
		t.Fatal("expected error for empty ISBN")
	}
}

func TestJsonResponse_Error(t *testing.T) {
	resp, err := jsonResponse(nil, errors.New("boom"))
	if err != nil {
		t.Fatalf("jsonResponse returned error: %v", err)
	}
	if resp.StatusCode != http.StatusInternalServerError {
		t.Fatalf("expected 500, got %d", resp.StatusCode)
	}
	var payload map[string]any
	if uErr := json.Unmarshal([]byte(resp.Body), &payload); uErr != nil {
		t.Fatalf("invalid json body: %v", uErr)
	}
	body, ok := payload["body"].(map[string]any)
	if !ok {
		t.Fatalf("missing body object in response: %#v", payload)
	}
	if body["error"] != "boom" {
		t.Fatalf("expected error boom, got %#v", body["error"])
	}
}

func TestJsonResponse_Success(t *testing.T) {
	in := types.Response{Body: types.ResponseBody{Books: []interface{}{"x"}}}
	resp, err := jsonResponse(in, nil)
	if err != nil {
		t.Fatalf("jsonResponse returned error: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
	if resp.Headers["X-Lambda-Handler"] == "" {
		t.Fatal("expected X-Lambda-Handler header")
	}
}

func TestHandler_EmptyQueryReturnsErrorPayload(t *testing.T) {
	resp, err := handler(context.Background(), events.APIGatewayV2HTTPRequest{
		QueryStringParameters: map[string]string{},
	})
	if err != nil {
		t.Fatalf("handler returned error: %v", err)
	}
	if resp.StatusCode != http.StatusInternalServerError {
		t.Fatalf("expected 500, got %d", resp.StatusCode)
	}
}

func TestHandler_EmptyRawQueryReturnsErrorPayload(t *testing.T) {
	resp, err := handler(context.Background(), events.APIGatewayV2HTTPRequest{
		RawQueryString: "foo=bar",
	})
	if err != nil {
		t.Fatalf("handler returned error: %v", err)
	}
	if resp.StatusCode != http.StatusInternalServerError {
		t.Fatalf("expected 500, got %d", resp.StatusCode)
	}
}

