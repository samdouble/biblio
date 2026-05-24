package auth

import (
	"errors"
	"fmt"
	"os"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

const (
	bearerPrefix = "Bearer "
	issuer       = "tsunbooku-api"
)

func secret() (string, error) {
	s := strings.TrimSpace(os.Getenv("AUTH_JWT_SECRET"))
	if s == "" {
		return "", errors.New("missing AUTH_JWT_SECRET")
	}
	return s, nil
}

func IssueUserToken(userID string) (string, error) {
	userID = strings.TrimSpace(userID)
	if userID == "" {
		return "", errors.New("user id is required")
	}
	secret, err := secret()
	if err != nil {
		return "", err
	}
	now := time.Now().UTC()
	claims := jwt.RegisteredClaims{
		Subject:   userID,
		Issuer:    issuer,
		IssuedAt:  jwt.NewNumericDate(now),
		ExpiresAt: jwt.NewNumericDate(now.Add(30 * 24 * time.Hour)),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

func UserIDFromAuthorizationHeader(authHeader string) (string, error) {
	authHeader = strings.TrimSpace(authHeader)
	if !strings.HasPrefix(authHeader, bearerPrefix) {
		return "", errors.New("missing bearer token")
	}
	rawToken := strings.TrimSpace(strings.TrimPrefix(authHeader, bearerPrefix))
	if rawToken == "" {
		return "", errors.New("missing bearer token")
	}
	secret, err := secret()
	if err != nil {
		return "", err
	}
	claims := &jwt.RegisteredClaims{}
	parsed, err := jwt.ParseWithClaims(rawToken, claims, func(token *jwt.Token) (interface{}, error) {
		if token.Method != jwt.SigningMethodHS256 {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Method.Alg())
		}
		return []byte(secret), nil
	})
	if err != nil || !parsed.Valid {
		return "", errors.New("invalid bearer token")
	}
	if claims.Subject == "" {
		return "", errors.New("invalid bearer token")
	}
	return claims.Subject, nil
}
