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
	"encoding/json"
	"net/http"

	"go.zoe.im/payserver/server/core"
	"go.zoe.im/x/httputil"
)

// HandlePrepareAgent generate a ticket to register agent
func (wa *WebAPI) HandlePrepareAgent(w http.ResponseWriter, r *http.Request) {
	// generate a ticket and return server information
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	wr.WithDataOrErr(wa.PrepareAgent())
}

// HandleRegisterAgent register to an agent
func (wa *WebAPI) HandleRegisterAgent(w http.ResponseWriter, r *http.Request) {
	// register an agent
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	// check the ticket, auto bind to app by ticket

	// only care: device_id, device_info, external
	defer r.Body.Close()
	var agent core.Agent
	if err := json.NewDecoder(r.Body).Decode(&agent); err != nil {
		wr.WithCode(101).WithErrorf("decode order error: %s", err)
		return
	}

	wr.WithDataOrErr(wa.RegisterAgent(&agent))
}

// HandleListAgents list all agent by <user>
func (wa *WebAPI) HandleListAgents(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	wr.WithDataOrErr(wa.ListAgents())
}

func (wa *WebAPI) HandleGetAgent(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

func (wa *WebAPI) HandleDeleteAgent(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

func (wa *WebAPI) HandleUpdateAgent(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

func (wa *WebAPI) HandleListAppsByAgent(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

func (wa *WebAPI) HandleListRecordsByAgent(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

// HandleHeartbeatAgent handle the heartbeat from device
func (wa *WebAPI) HandleHeartbeatAgent(w http.ResponseWriter, r *http.Request) {
	// register with the id
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}