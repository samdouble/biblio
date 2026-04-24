package main

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"

	"biblio-api/db"
	"biblio-api/models"
	"biblio-api/otps"
	"biblio-api/testutil"
	"biblio-api/types"
)

func TestHashOtp(t *testing.T) {
	const code = "123456"
	h1 := hashOtp(code)
	h2 := hashOtp(code)
	if h1 != h2 {
		t.Errorf("hashOtp should be deterministic: %q != %q", h1, h2)
	}
	if len(h1) != 64 {
		t.Errorf("hashOtp: SHA256 hex should be 64 chars, got %d", len(h1))
	}
	if hashOtp("654321") == h1 {
		t.Error("hashOtp: different input should produce different hash")
	}
}

func TestMain_EmptyEmail(t *testing.T) {
	ctx := context.Background()
	event := types.VerifyOtpEvent{Email: "", Otp: "123456"}
	resp, err := Main(ctx, event)
	if err == nil {
		t.Fatal("Main: expected error for empty email")
	}
	if resp.Body.Error != "email is required" {
		t.Errorf("Main: expected body error 'email is required', got %q", resp.Body.Error)
	}
	if resp.Body.UserId != "" || resp.Body.Email != "" {
		t.Error("Main: UserId and Email should be empty on error")
	}
}

func TestMain_EmptyOtp(t *testing.T) {
	ctx := context.Background()
	cases := []struct {
		name string
		otp  string
	}{
		{"empty", ""},
		{"whitespace", "   "},
		{"tab", "\t"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			event := types.VerifyOtpEvent{Email: "user@example.com", Otp: c.otp}
			resp, err := Main(ctx, event)
			if err == nil {
				t.Fatal("Main: expected error for empty otp")
			}
			if resp.Body.Error != "code is required" {
				t.Errorf("Main: expected body error 'code is required', got %q", resp.Body.Error)
			}
			if resp.Body.UserId != "" || resp.Body.Email != "" {
				t.Error("Main: UserId and Email should be empty on error")
			}
		})
	}
}

func TestJsonResponse_errorAndSuccess(t *testing.T) {
	t.Run("error", func(t *testing.T) {
		resp, err := jsonResponse(types.VerifyOtpResponse{}, errors.New("email is required"))
		if err != nil {
			t.Fatalf("jsonResponse: %v", err)
		}
		if resp.StatusCode != 500 || resp.Headers["Content-Type"] != "application/json" {
			t.Fatalf("unexpected response: %+v", resp)
		}
	})
	t.Run("success", func(t *testing.T) {
		resp, err := jsonResponse(types.VerifyOtpResponse{
			Body: types.VerifyOtpResponseBody{UserId: "u1", Email: "a@b.co"},
		}, nil)
		if err != nil {
			t.Fatalf("jsonResponse: %v", err)
		}
		if resp.StatusCode != 200 {
			t.Fatalf("status %d", resp.StatusCode)
		}
	})
}

func TestHandler_emptyBody_emailRequired(t *testing.T) {
	resp, err := handler(context.Background(), events.APIGatewayV2HTTPRequest{})
	if err != nil {
		t.Fatalf("handler: %v", err)
	}
	if resp.StatusCode != 500 {
		t.Fatalf("status %d", resp.StatusCode)
	}
}

func TestMain_noOtpRecord(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "verifyotp")
	ctx := context.Background()
	resp, err := Main(ctx, types.VerifyOtpEvent{Email: "nobody@example.com", Otp: "123456"})
	if err == nil {
		t.Fatal("expected error")
	}
	if resp.Body.Error != "invalid or expired code" {
		t.Fatalf("unexpected error %q", resp.Body.Error)
	}
}

func TestMain_wrongOtp(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "verifyotp")
	ctx := context.Background()
	email := "wrong@example.com"
	if err := otps.Upsert(dbForTest(t), email, hashOtp("111111")); err != nil {
		t.Fatalf("Upsert: %v", err)
	}
	resp, err := Main(ctx, types.VerifyOtpEvent{Email: email, Otp: "999999"})
	if err == nil {
		t.Fatal("expected error")
	}
	if resp.Body.Error != "invalid or expired code" {
		t.Fatalf("unexpected error %q", resp.Body.Error)
	}
}

func TestMain_expiredOtp(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "verifyotp")
	ctx := context.Background()
	email := "expired@example.com"
	database := dbForTest(t)
	coll := database.Collection(otps.CollectionName)
	_, err := coll.InsertOne(ctx, bson.M{
		"email":     email,
		"otpHash":   hashOtp("222222"),
		"expiresAt": time.Now().UTC().Add(-time.Hour),
	})
	if err != nil {
		t.Fatalf("InsertOne: %v", err)
	}
	resp, err := Main(ctx, types.VerifyOtpEvent{Email: email, Otp: "222222"})
	if err == nil {
		t.Fatal("expected error")
	}
	if resp.Body.Error != "code has expired" {
		t.Fatalf("unexpected error %q", resp.Body.Error)
	}
}

func TestMain_successNewUser(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "verifyotp")
	ctx := context.Background()
	email := "newuser@example.com"
	code := "333333"
	if err := otps.Upsert(dbForTest(t), email, hashOtp(code)); err != nil {
		t.Fatalf("Upsert: %v", err)
	}
	resp, err := Main(ctx, types.VerifyOtpEvent{Email: email, Otp: code})
	if err != nil {
		t.Fatalf("Main: %v", err)
	}
	if resp.Body.Error != "" || resp.Body.UserId == "" || resp.Body.Email != email {
		t.Fatalf("unexpected response %+v", resp.Body)
	}
	stored, err := models.GetUserByEmail(dbForTest(t), email)
	if err != nil {
		t.Fatalf("GetUserByEmail: %v", err)
	}
	if stored == nil || stored.Id != resp.Body.UserId {
		t.Fatalf("user not persisted: %+v", stored)
	}
}

func TestMain_successExistingUser(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "verifyotp")
	ctx := context.Background()
	email := "existing@example.com"
	existing := types.User{
		Id:        "user-persisted-1",
		Email:     email,
		Name:      "Pat",
		CreatedAt: time.Now().UTC().Truncate(time.Millisecond),
	}
	if err := models.InsertUser(dbForTest(t), existing); err != nil {
		t.Fatalf("InsertUser: %v", err)
	}
	code := "444444"
	if err := otps.Upsert(dbForTest(t), email, hashOtp(code)); err != nil {
		t.Fatalf("Upsert: %v", err)
	}
	resp, err := Main(ctx, types.VerifyOtpEvent{Email: email, Otp: code})
	if err != nil {
		t.Fatalf("Main: %v", err)
	}
	if resp.Body.UserId != existing.Id || resp.Body.Email != email {
		t.Fatalf("unexpected response %+v", resp.Body)
	}
}

func TestHandler_JSONBody_successNewUser(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "verifyotp")
	email := "handler-new@example.com"
	code := "555555"
	if err := otps.Upsert(dbForTest(t), email, hashOtp(code)); err != nil {
		t.Fatalf("Upsert: %v", err)
	}
	body := `{"email":"` + email + `","otp":"` + code + `"}`
	resp, err := handler(context.Background(), events.APIGatewayV2HTTPRequest{Body: body})
	if err != nil {
		t.Fatalf("handler: %v", err)
	}
	if resp.StatusCode != 200 {
		t.Fatalf("status %d %s", resp.StatusCode, resp.Body)
	}
	var parsed types.VerifyOtpResponse
	if err := json.Unmarshal([]byte(resp.Body), &parsed); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if parsed.Body.Error != "" || parsed.Body.Email != email {
		t.Fatalf("response %+v", parsed.Body)
	}
}

func dbForTest(t *testing.T) *mongo.Database {
	t.Helper()
	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	return client.Database(os.Getenv("MONGO_DBNAME"))
}
