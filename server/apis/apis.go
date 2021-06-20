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

package apis

import (
	"github.com/gorilla/mux"

	"go.zoe.im/payserver/server/server"
)

// TODO: auto generated from server.Server

type WebAPI struct {
	*server.Server
}

func (wa *WebAPI) Register(apiv1 *mux.Router) {
	apiv1.HandleFunc("/order", wa.HandleCreateOrder).Methods("POST")
	apiv1.HandleFunc("/order/{uid}", wa.HandleGetOrder).Methods("GET")
	apiv1.HandleFunc("/order/{uid}/cancel", wa.HandleCancelOrder).Methods("POST") // TODO???
	apiv1.HandleFunc("/order/{uid}/status", wa.HandleGetOrderStatus).Methods("GET")

	apiv1.HandleFunc("/records", wa.HandleCreateRecord).Methods("POST")
	apiv1.HandleFunc("/record/{uid}", wa.HandleGetRecord).Methods("GET")
	apiv1.HandleFunc("/records", wa.HandleListRecords).Methods("GET") // TODO: by create time?

	apiv1.HandleFunc("/agent/prepare", wa.HandlePrepareAgent).Methods("GET")
	apiv1.HandleFunc("/agents", wa.HandleRegisterAgent).Methods("POST")
	apiv1.HandleFunc("/agents", wa.HandleListAgents).Methods("GET") // TODO: add filter?
	apiv1.HandleFunc("/agent/{uid}", wa.HandleGetAgent).Methods("GET")
	apiv1.HandleFunc("/agent/{uid}", wa.HandleDeleteAgent).Methods("DELETE")
	apiv1.HandleFunc("/agent/{uid}", wa.HandleUpdateAgent).Methods("POST")
	apiv1.HandleFunc("/agent/{uid}/heartbeat", wa.HandleHeartbeatAgent).Methods("POST")
	apiv1.HandleFunc("/agent/{uid}/apps", wa.HandleListAppsByAgent).Methods("GET")
	apiv1.HandleFunc("/agent/{uid}/records", wa.HandleListRecordsByAgent).Methods("GET")

	apiv1.HandleFunc("/apps", wa.HandleListApp).Methods("GET")
	apiv1.HandleFunc("/apps", wa.HandleCreateApp).Methods("POST")
	apiv1.HandleFunc("/app/{uid}", wa.HandleGetApp).Methods("GET")
	apiv1.HandleFunc("/app/{uid}", wa.HandleDeleteApp).Methods("DELETE")
	apiv1.HandleFunc("/app/{uid}", wa.HandleUpdateApp).Methods("POST")
	apiv1.HandleFunc("/app/{uid}/agents", wa.HandleListAgentsByApp).Methods("GET")
	apiv1.HandleFunc("/app/{uid}/records", wa.HandleListRecordsByApp).Methods("GET")
}

func NewWebAPI(s *server.Server) *WebAPI {
	return &WebAPI{
		Server: s,
	}
}
