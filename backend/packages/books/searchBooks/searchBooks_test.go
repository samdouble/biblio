package main

import (
	"regexp"
	"testing"
)

func TestBuildAccentInsensitivePattern_MatchesDiacriticsAndCase(t *testing.T) {
	tests := []struct {
		query  string
		target string
	}{
		{query: "resume", target: "Résumé"},
		{query: "garcia", target: "García"},
		{query: "francois", target: "François"},
		{query: "soren", target: "Søren"},
		{query: "MUNCHEN", target: "München"},
	}

	for _, tc := range tests {
		pattern := buildAccentInsensitivePattern(tc.query)
		re, err := regexp.Compile("(?i)" + pattern)
		if err != nil {
			t.Fatalf("failed to compile pattern %q: %v", pattern, err)
		}
		if !re.MatchString(tc.target) {
			t.Fatalf("pattern %q should match %q for query %q", pattern, tc.target, tc.query)
		}
	}
}
