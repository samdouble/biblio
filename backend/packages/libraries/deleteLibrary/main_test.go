package main

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"testing"

	"github.com/aws/aws-lambda-go/events"

	"tsundoku-api/auth"
	"tsundoku-api/types"
)

func authHeaderForTest(t *testing.T) string {
	t.Helper()
	t.Setenv("AUTH_JWT_SECRET", "test-secret")
	token, err := auth.IssueUserToken("user-1")
	if err != nil {
		t.Fatalf("IssueUserToken: %v", err)
	}
	return "Bearer " + token
}

func TestMain_RequiresUserId(t *testing.T) {
	resp, err := Main(context.Background(), types.DeleteLibraryEvent{
		UserId:    "   ",
		LibraryId: "lib-1",
	})
	if err == nil {
		t.Fatal("expected error when userId is empty")
	}
	if resp.Body.Error != "user id is required" {
		t.Fatalf("unexpected response error: %q", resp.Body.Error)
	}
}

func TestMain_RequiresLibraryId(t *testing.T) {
	resp, err := Main(context.Background(), types.DeleteLibraryEvent{
		UserId:    "user-1",
		LibraryId: "   ",
	})
	if err == nil {
		t.Fatal("expected error when libraryId is empty")
	}
	if resp.Body.Error != "library id is required" {
		t.Fatalf("unexpected response error: %q", resp.Body.Error)
	}
}

func TestHandler_InvalidBodyReturnsValidationError(t *testing.T) {
	resp, err := handler(context.Background(), events.APIGatewayV2HTTPRequest{
		Body:    "{invalid json",
		Headers: map[string]string{"authorization": authHeaderForTest(t)},
	})
	if err != nil {
		t.Fatalf("handler returned error: %v", err)
	}
	if resp.StatusCode != http.StatusInternalServerError {
		t.Fatalf("expected 500 status, got %d", resp.StatusCode)
	}
}

func TestHandler_UsesPathParameterForLibraryId(t *testing.T) {
	resp, err := handler(context.Background(), events.APIGatewayV2HTTPRequest{
		Body:           `{}`,
		Headers:        map[string]string{"authorization": authHeaderForTest(t)},
	})
	if err != nil {
		t.Fatalf("handler returned error: %v", err)
	}
	if resp.StatusCode != http.StatusInternalServerError {
		t.Fatalf("expected 500 status, got %d", resp.StatusCode)
	}
	var payload map[string]any
	if uErr := json.Unmarshal([]byte(resp.Body), &payload); uErr != nil {
		t.Fatalf("invalid body json: %v", uErr)
	}
	body, ok := payload["body"].(map[string]any)
	if !ok {
		t.Fatalf("missing body object: %#v", payload)
	}
	if body["error"] != "library id is required" {
		t.Fatalf("expected library id validation error, got %#v", body["error"])
	}
}

func TestJsonResponse_Success(t *testing.T) {
	in := types.DeleteLibraryResponse{Body: types.DeleteLibraryResponseBody{}}
	resp, err := jsonResponse(in, nil)
	if err != nil {
		t.Fatalf("jsonResponse returned error: %v", err)
	}
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200, got %d", resp.StatusCode)
	}
	var payload map[string]any
	if uErr := json.Unmarshal([]byte(resp.Body), &payload); uErr != nil {
		t.Fatalf("invalid body json: %v", uErr)
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
		t.Fatalf("invalid body json: %v", uErr)
	}
	body, ok := payload["body"].(map[string]any)
	if !ok {
		t.Fatalf("missing body object: %#v", payload)
	}
	if body["error"] != "boom" {
		t.Fatalf("expected boom error, got %#v", body["error"])
	}
}
