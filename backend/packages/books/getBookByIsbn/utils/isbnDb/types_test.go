package types

import (
	"encoding/json"
	"testing"
)

func TestUnmarshalJSON_UsesDataFieldWhenPresent(t *testing.T) {
	var out IsbnDbSearchBooksResponse
	err := json.Unmarshal([]byte(`{"total":1,"page":1,"pageSize":20,"data":[{"title":"D"}],"books":[{"title":"B"}]}`), &out)
	if err != nil {
		t.Fatalf("unmarshal failed: %v", err)
	}
	if len(out.Data) != 1 || out.Data[0].Title != "D" {
		t.Fatalf("expected data field, got %#v", out.Data)
	}
}

func TestUnmarshalJSON_FallsBackToBooksField(t *testing.T) {
	var out IsbnDbSearchBooksResponse
	err := json.Unmarshal([]byte(`{"total":1,"page":1,"pageSize":20,"books":[{"title":"B"}]}`), &out)
	if err != nil {
		t.Fatalf("unmarshal failed: %v", err)
	}
	if len(out.Data) != 1 || out.Data[0].Title != "B" {
		t.Fatalf("expected books fallback, got %#v", out.Data)
	}
}
