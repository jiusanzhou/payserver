package utils

import (
	"net/http"
)

func WithHeader(key string, valueFn func(r *http.Request) string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		fn := func(w http.ResponseWriter, r *http.Request) {
			w.Header().Add(key, valueFn(r))
			next.ServeHTTP(w, r)
		}
		return http.HandlerFunc(fn)
	}
}

func NullIfErr(data interface{}, err error) (interface{}, error) {
	if err != nil {
		return nil, err
	}
	return data, nil
}
