package main

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"regexp"
	"testing"

	"github.com/aws/aws-lambda-go/events"

	"tsunbooku-api/db"
	"tsunbooku-api/otps"
	"tsunbooku-api/testutil"
	"tsunbooku-api/types"
)

func TestGenerateOtp(t *testing.T) {
	const digits = 6
	for i := 0; i < 20; i++ {
		otp, err := generateOtp(digits)
		if err != nil {
			t.Fatalf("generateOtp: %v", err)
		}
		if len(otp) != digits {
			t.Errorf("generateOtp: expected length %d, got %d", digits, len(otp))
		}
		if ok, _ := regexp.MatchString(`^\d+$`, otp); !ok {
			t.Errorf("generateOtp: expected only digits, got %q", otp)
		}
	}
}

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
	cases := []struct {
		name  string
		email string
	}{
		{"empty", ""},
		{"whitespace", "   "},
		{"tab", "\t"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			event := types.SendOtpEvent{Email: c.email}
			resp, err := Main(ctx, event)
			if err == nil {
				t.Fatal("Main: expected error for empty email")
			}
			if resp.Body.Error != "email is required" {
				t.Errorf("Main: expected body error 'email is required', got %q", resp.Body.Error)
			}
			if resp.Body.Sent {
				t.Error("Main: Sent should be false")
			}
		})
	}
}

func TestJsonResponse_errorAndSuccess(t *testing.T) {
	t.Run("error", func(t *testing.T) {
		resp, err := jsonResponse(types.SendOtpResponse{}, errors.New("email is required"))
		if err != nil {
			t.Fatalf("jsonResponse: %v", err)
		}
		if resp.StatusCode != 500 {
			t.Fatalf("status %d", resp.StatusCode)
		}
		if resp.Headers["Content-Type"] != "application/json" || resp.Headers["X-Lambda-Handler"] != "AuthSendOtp" {
			t.Fatalf("headers: %+v", resp.Headers)
		}
	})
	t.Run("success", func(t *testing.T) {
		resp, err := jsonResponse(types.SendOtpResponse{Body: types.SendOtpResponseBody{Sent: true}}, nil)
		if err != nil {
			t.Fatalf("jsonResponse: %v", err)
		}
		if resp.StatusCode != 200 {
			t.Fatalf("status %d", resp.StatusCode)
		}
		if resp.Headers["X-Lambda-Handler"] != "AuthSendOtp" {
			t.Fatalf("headers: %+v", resp.Headers)
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

func TestHandler_JSONBody_roundTrip(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "sendotp")
	orig := sendOtpEmail
	sendOtpEmail = func(context.Context, string, string, string) error { return nil }
	t.Cleanup(func() { sendOtpEmail = orig })

	body := `{"email":"  User@Example.COM  "}`
	resp, err := handler(context.Background(), events.APIGatewayV2HTTPRequest{Body: body})
	if err != nil {
		t.Fatalf("handler: %v", err)
	}
	if resp.StatusCode != 200 {
		t.Fatalf("status %d body %s", resp.StatusCode, resp.Body)
	}
	var parsed types.SendOtpResponse
	if err := json.Unmarshal([]byte(resp.Body), &parsed); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if !parsed.Body.Sent || parsed.Body.Error != "" {
		t.Fatalf("response %+v", parsed)
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))
	rec, err := otps.GetByEmail(database, "user@example.com")
	if err != nil {
		t.Fatalf("GetByEmail: %v", err)
	}
	if rec == nil || rec.OtpHash == "" || rec.Email != "user@example.com" {
		t.Fatalf("unexpected otp record %+v", rec)
	}
}

func TestMain_sendEmailFailure(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "sendotp")
	orig := sendOtpEmail
	sendOtpEmail = func(context.Context, string, string, string) error {
		return errors.New("ses unavailable")
	}
	t.Cleanup(func() { sendOtpEmail = orig })

	ctx := context.Background()
	resp, err := Main(ctx, types.SendOtpEvent{Email: "fail@example.com"})
	if err == nil {
		t.Fatal("Main: expected error when SES fails")
	}
	if resp.Body.Error != "failed to send code" {
		t.Fatalf("unexpected body error %q", resp.Body.Error)
	}
	if resp.Body.Sent {
		t.Fatal("Main: Sent should be false")
	}
}

func TestMain_SendsOtp_storesRecord(t *testing.T) {
	testutil.SetupIntegrationMongo(t, "sendotp")
	orig := sendOtpEmail
	sendOtpEmail = func(context.Context, string, string, string) error { return nil }
	t.Cleanup(func() { sendOtpEmail = orig })

	ctx := context.Background()
	resp, err := Main(ctx, types.SendOtpEvent{Email: "  User@Example.COM  "})
	if err != nil {
		t.Fatalf("Main: %v", err)
	}
	if !resp.Body.Sent || resp.Body.Error != "" {
		t.Fatalf("unexpected response %+v", resp)
	}

	client := db.ResolveClientDB(os.Getenv("MONGO_URL"))
	database := client.Database(os.Getenv("MONGO_DBNAME"))
	rec, err := otps.GetByEmail(database, "user@example.com")
	if err != nil {
		t.Fatalf("GetByEmail: %v", err)
	}
	if rec == nil || rec.OtpHash == "" || rec.Email != "user@example.com" {
		t.Fatalf("unexpected otp record %+v", rec)
	}
}
