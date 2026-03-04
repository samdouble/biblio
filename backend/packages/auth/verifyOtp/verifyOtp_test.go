package main

import (
	"context"
	"testing"

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
