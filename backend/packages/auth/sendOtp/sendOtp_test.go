package main

import (
	"context"
	"regexp"
	"testing"

	"biblio-api/types"
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
