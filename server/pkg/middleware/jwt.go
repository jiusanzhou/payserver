/*
 * Copyright (c) 2021 wellwell.work, LLC by Zoe
 *
 * Licensed under the Apache License 2.0 (the "License");
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package middleware

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// ContextKey for storing user info in request context
type ContextKey string

const (
	// UserContextKey is the key for user info in context
	UserContextKey ContextKey = "user"
)

// Claims represents JWT claims
type Claims struct {
	jwt.RegisteredClaims
	UserID   string `json:"user_id,omitempty"`
	Email    string `json:"email,omitempty"`
	Role     string `json:"role,omitempty"`
	AppID    string `json:"app_id,omitempty"`    // For API key auth
	AgentUID string `json:"agent_uid,omitempty"` // For agent auth
}

// JWTConfig holds JWT middleware configuration
type JWTConfig struct {
	// Secret key for HS256 signing (for self-signed tokens)
	Secret string

	// Supabase JWT secret (from Supabase dashboard)
	SupabaseSecret string

	// Skip authentication for these paths
	SkipPaths []string

	// Allow API key authentication via X-API-Key header
	AllowAPIKey bool

	// API key validator function
	ValidateAPIKey func(apiKey string) (*Claims, error)
}

// JWTMiddleware creates a JWT authentication middleware
func JWTMiddleware(config *JWTConfig) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Check if path should skip authentication
			for _, path := range config.SkipPaths {
				if strings.HasPrefix(r.URL.Path, path) {
					next.ServeHTTP(w, r)
					return
				}
			}

			var claims *Claims
			var err error

			// Try API key authentication first
			if config.AllowAPIKey {
				apiKey := r.Header.Get("X-API-Key")
				if apiKey != "" && config.ValidateAPIKey != nil {
					claims, err = config.ValidateAPIKey(apiKey)
					if err == nil && claims != nil {
						ctx := context.WithValue(r.Context(), UserContextKey, claims)
						next.ServeHTTP(w, r.WithContext(ctx))
						return
					}
				}
			}

			// Try Bearer token authentication
			authHeader := r.Header.Get("Authorization")
			if authHeader == "" {
				writeUnauthorized(w, "missing authorization header")
				return
			}

			parts := strings.Split(authHeader, " ")
			if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
				writeUnauthorized(w, "invalid authorization header format")
				return
			}

			tokenString := parts[1]

			// Try Supabase secret first, then fallback to custom secret
			claims, err = validateToken(tokenString, config.SupabaseSecret)
			if err != nil && config.Secret != "" {
				claims, err = validateToken(tokenString, config.Secret)
			}

			if err != nil {
				writeUnauthorized(w, "invalid token: "+err.Error())
				return
			}

			// Add claims to context
			ctx := context.WithValue(r.Context(), UserContextKey, claims)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// validateToken validates a JWT token and returns claims
func validateToken(tokenString, secret string) (*Claims, error) {
	if secret == "" {
		return nil, errors.New("no secret configured")
	}

	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		// Validate signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return []byte(secret), nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token claims")
	}

	return claims, nil
}

// GetUserFromContext retrieves user claims from request context
func GetUserFromContext(ctx context.Context) (*Claims, bool) {
	claims, ok := ctx.Value(UserContextKey).(*Claims)
	return claims, ok
}

// RequireRole middleware ensures user has required role
func RequireRole(roles ...string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			claims, ok := GetUserFromContext(r.Context())
			if !ok {
				writeUnauthorized(w, "no user in context")
				return
			}

			for _, role := range roles {
				if claims.Role == role {
					next.ServeHTTP(w, r)
					return
				}
			}

			writeForbidden(w, "insufficient permissions")
		})
	}
}

// GenerateToken creates a new JWT token
func GenerateToken(secret string, claims *Claims, expiry time.Duration) (string, error) {
	now := time.Now()
	claims.RegisteredClaims = jwt.RegisteredClaims{
		ExpiresAt: jwt.NewNumericDate(now.Add(expiry)),
		IssuedAt:  jwt.NewNumericDate(now),
		NotBefore: jwt.NewNumericDate(now),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(secret))
}

// Helper functions for HTTP responses
func writeUnauthorized(w http.ResponseWriter, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnauthorized)
	json.NewEncoder(w).Encode(map[string]string{
		"error":   "unauthorized",
		"message": message,
	})
}

func writeForbidden(w http.ResponseWriter, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusForbidden)
	json.NewEncoder(w).Encode(map[string]string{
		"error":   "forbidden",
		"message": message,
	})
}
