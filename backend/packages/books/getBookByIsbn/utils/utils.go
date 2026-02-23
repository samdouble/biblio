package utils

func ConvertToInterface[T any](arr []T) []interface{} {
	var result []interface{}
	for _, item := range arr {
		result = append(result, item)
	}
	return result
}
