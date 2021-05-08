package service

import (
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/mux"

	"go.zoe.im/payserver/server/utils"
	"go.zoe.im/x/version"
	// "go.zoe.im/payserver/server/ui"
)

// HandleHealth ...
func HandleHealth(w http.ResponseWriter, r *http.Request) {
	w.Write([]byte("ok"))
}

// HandleStat ...
func HandleStat(w http.ResponseWriter, r *http.Request) {
	// TODO: return stat of the process
}

func (s *Server) installHandler(r *mux.Router) {
	r.HandleFunc("/_healthz", HandleHealth)

	// install ui
	// r.NotFoundHandler = ui.NewHandler(ui.Prefix(s.Config.RootPath))

	apiv1 := r.PathPrefix("/api/v1/").Subrouter()

	if s.Config.HTTPAllowOrigin != "" {
		log.Println("add access-control-allow-origin:", s.Config.HTTPAllowOrigin)
		r.Use(utils.WithHeader("Access-Control-Allow-Origin", func(r *http.Request) string { return s.Config.HTTPAllowOrigin }))
	}

	NewWebAPI(s).Register(apiv1)
}

func (s *Server) startHTTP() error {

	r := mux.NewRouter()

	s.installHandler(r)

	fmt.Printf("Welcome to have payserver(%s)!\nListen payserver service on: %s\n", version.GitVersion, s.Config.Addr)

	return http.ListenAndServe(s.Config.Addr, r)
}
