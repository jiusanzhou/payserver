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

package service

import (
	"encoding/json"
	"net/http"

	"github.com/gorilla/mux"
	"go.zoe.im/payserver/server/core"
	"go.zoe.im/x/httputil"
)

type WebAPI struct {
	*Server
}

func NewWebAPI(s *Server) *WebAPI {
	return &WebAPI{
		Server: s,
	}
}

func (wa *WebAPI) Register(apiv1 *mux.Router) {
	apiv1.HandleFunc("/order", wa.HandleCreateOrder).Methods("POST")
	apiv1.HandleFunc("/order", wa.HandleGetOrder).Methods("GET")
	apiv1.HandleFunc("/order/status", wa.HandleGetOrderStatus).Methods("GET")
}

func (wa *WebAPI) HandleCreateOrder(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	var preOrder core.PreOrder
	if err := json.NewDecoder(r.Body).Decode(&preOrder); err != nil {
		wr.WithError(err).Flush()
		return
	}

	wr.WithDataOrErr(wa.CreateOrder(&preOrder)).Flush()
}

func (wa *WebAPI) HandleGetOrder(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)

	uid := r.URL.Query().Get("uid") // not outer id
	if uid == "" {
		wr.WithErrorf("must need uid").Flush()
		return
	}
	
	wr.WithDataOrErr(wa.GetOrder(uid)).Flush()
}

func (wa *WebAPI) HandleGetOrderStatus(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)

	uid := r.URL.Query().Get("uid") // not outer id
	if uid == "" {
		wr.WithErrorf("must need uid").Flush()
		return
	}
	
	wr.WithDataOrErr(wa.GetOrderStatus(uid)).Flush()
}

func init() {
	httputil.HTTPStatusFromCode(func(_ httputil.StatusCode) int {
		return 200
	})
}
