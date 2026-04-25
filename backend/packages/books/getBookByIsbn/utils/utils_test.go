package utils

import "testing"

func TestConvertToInterface(t *testing.T) {
	in := []int{1, 2, 3}
	out := ConvertToInterface(in)
	if len(out) != 3 {
		t.Fatalf("expected len 3, got %d", len(out))
	}
	if out[0].(int) != 1 || out[2].(int) != 3 {
		t.Fatalf("unexpected values: %#v", out)
	}
}

