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
	"strconv"
	"time"

	"github.com/gorilla/mux"
	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/utils"
	"go.zoe.im/x/httputil"
)

// HandlePrepareAgent generate a ticket to register agent
func (wa *WebAPI) HandlePrepareAgent(w http.ResponseWriter, r *http.Request) {
	// generate a ticket and return server information
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var agent core.Agent
	if err := json.NewDecoder(r.Body).Decode(&agent); err != nil {
		wr.WithCode(101).WithErrorf("decode agent error: %s", err)
		return
	}

	if agent.DeviceID == "" {
		wr.WithCode(103).WithErrorf("deviceid can't be empty")
		return
	}

	wr.WithDataOrErr(wa.PrepareAgent(&agent))
}

// HandleRegisterAgent register to an agent
func (wa *WebAPI) HandleRegisterAgent(w http.ResponseWriter, r *http.Request) {
	// register an agent
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	// check the ticket, auto bind to app by ticket

	// only care: device_id, device_info, external

	var agent core.Agent
	if err := json.NewDecoder(r.Body).Decode(&agent); err != nil {
		wr.WithCode(101).WithErrorf("decode agent error: %s", err)
		return
	}

	if agent.Ticket == "" {
		wr.WithCode(102).WithErrorf("ticket is empty")
		return
	}

	if agent.DeviceID == "" {
		wr.WithCode(103).WithErrorf("deviceid can't be empty")
		return
	}

	if agent.PayTypes == "" {
		wr.WithCode(104).WithErrorf("must offer at least 1 pay types")
		return
	}

	wr.WithDataOrErr(wa.RegisterAgent(&agent))
}

// HandleListAgents list all agent by <user>
func (wa *WebAPI) HandleListAgents(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	offset := 0
	limit := 10

	q := r.URL.Query()

	if o, err := strconv.Atoi(q.Get("offset")); err == nil {
		offset = o
	}

	if l, err := strconv.Atoi(q.Get("limit")); err == nil && l < 50 {
		limit = l
	}

	wr.WithDataOrErr(wa.ListAgents(offset, limit))
}

func (wa *WebAPI) HandleGetAgent(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("agent id can't be empty")
		return
	}

	wr.WithDataOrErr(utils.NullIfErr(wa.GetAgent(uid)))
}

func (wa *WebAPI) HandleDeleteAgent(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("agent id can't be empty")
		return
	}

	wr.WithDataOrErr(nil, wa.DeleteAgent(uid))

}

func (wa *WebAPI) HandleUpdateAgent(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("agent id can't be empty")
		return
	}

	// marshal agent from body
	var agent core.Agent
	if err := json.NewDecoder(r.Body).Decode(&agent); err != nil {
		wr.WithCode(101).WithErrorf("decode agent error: %s", err)
		return
	}

	// TODO: validate
	if agent.PayTypes == "" {
		wr.WithCode(103).WithErrorf("must offer at least 1 pay types")
		return
	}

	// TODO: auto reset
	agent.CreateAt = time.Time{}
	agent.UpdatedAt = time.Time{}
	agent.DeletedAt = &time.Time{}

	agent.ID = 0
	agent.Ticket = ""
	agent.UID = ""

	// only keep: device_info, external, status, pay_types, device_id, heartbeat_at

	wr.WithDataOrErr(wa.UpdateAgent(uid, &agent))
}

func (wa *WebAPI) HandleListAppsByAgent(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("agent id can't be empty")
		return
	}

	offset := 0
	limit := 10

	q := r.URL.Query()

	if o, err := strconv.Atoi(q.Get("offset")); err == nil {
		offset = o
	}

	if l, err := strconv.Atoi(q.Get("limit")); err == nil && l < 50 {
		limit = l
	}

	wr.WithDataOrErr(wa.ListAppsByAgent(uid, offset, limit))
}

func (wa *WebAPI) HandleListRecordsByAgent(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("agent id can't be empty")
		return
	}

	offset := 0
	limit := 10

	q := r.URL.Query()

	if o, err := strconv.Atoi(q.Get("offset")); err == nil {
		offset = o
	}

	if l, err := strconv.Atoi(q.Get("limit")); err == nil && l < 50 {
		limit = l
	}

	wr.WithDataOrErr(wa.ListRecordsByAgent(uid, offset, limit))
}

// HandleHeartbeatAgent handle the heartbeat from device
func (wa *WebAPI) HandleHeartbeatAgent(w http.ResponseWriter, r *http.Request) {
	// register with the id
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("agent id can't be empty")
		return
	}

	// TODO: add more information about device like location or status

	// update heartbeat_at
	_, err := wa.UpdateAgent(uid, &core.Agent{
		HeartbeatAt: time.Now(),
	})

	wr.WithError(err)
}
