package ingest

import (
	"testing"
)

func TestConfigFromEnv_defaults(t *testing.T) {
	t.Setenv("INGEST_FEED_ENABLED", "")
	t.Setenv("INGEST_MAX_FEED_PAGES", "")
	cfg := ConfigFromEnv()
	if !cfg.FeedEnabled {
		t.Fatal("expected feed enabled by default")
	}
	if cfg.MaxFeedPages != 3 || cfg.MaxAuthorsPerRun != 3 {
		t.Fatalf("unexpected defaults: %+v", cfg)
	}
}

func TestConfigFromEnv_overrides(t *testing.T) {
	t.Setenv("INGEST_FEED_ENABLED", "false")
	t.Setenv("INGEST_MAX_FEED_PAGES", "5")
	t.Setenv("INGEST_MAX_AUTHORS_PER_RUN", "10")
	cfg := ConfigFromEnv()
	if cfg.FeedEnabled {
		t.Fatal("expected feed disabled")
	}
	if cfg.MaxFeedPages != 5 || cfg.MaxAuthorsPerRun != 10 {
		t.Fatalf("unexpected overrides: %+v", cfg)
	}
}

func TestIsFeedUnavailable(t *testing.T) {
	if !isFeedUnavailable(errString("isbndb: feed unavailable (status 403)")) {
		t.Fatal("expected feed unavailable for 403")
	}
	if isFeedUnavailable(errString("other error")) {
		t.Fatal("expected false for unrelated error")
	}
}

type errString string

func (e errString) Error() string { return string(e) }
