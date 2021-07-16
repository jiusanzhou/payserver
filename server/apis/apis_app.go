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
	"strings"

	"github.com/gorilla/mux"
	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/utils"
	"go.zoe.im/x/httputil"
)

func (wa *WebAPI) HandleListApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	q := r.URL.Query()

	offset := 0
	limit := 10

	if o, err := strconv.Atoi(q.Get("offset")); err == nil {
		offset = o
	}

	if l, err := strconv.Atoi(q.Get("limit")); err == nil && l < 50 {
		limit = l
	}

	wr.WithDataOrErr(wa.ListApps(offset, limit))
}

func (wa *WebAPI) HandleCreateApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	// marshal agent from body
	var app core.App
	if err := json.NewDecoder(r.Body).Decode(&app); err != nil {
		wr.WithCode(101).WithErrorf("decode app error: %s", err)
		return
	}

	// TODO: validate
	// name can't be empty
	if app.Name == "" {
		wr.WithCode(201).WithErrorf("name is empty")
		return
	}

	// callback url can't be empty and should be URL
	if !strings.HasPrefix(app.CallbackURL, "http") {
		wr.WithCode(202).WithErrorf("callback shoube be a url")
		return
	}

	// 3600 >= expire >= 0
	if app.ExpireIn > 3600 || app.ExpireIn < 0 {
		wr.WithCode(203).WithErrorf("expire in shoule in range of (0, 3600]")
		return
	}

	// max pending order >= 0
	if app.MaxPenddingOrder < 0 {
		wr.WithCode(204).WithErrorf("max pendding order should > 0")
		return
	}

	if app.PriceCeil < 0 || app.PriceFloor < 0 {
		wr.WithCode(205).WithErrorf("price ceil and floor should be >= 0")
		return
	}

	wr.WithDataOrErr(wa.CreateApp(&app))
}

func (wa *WebAPI) HandleGetApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("app id can't be empty")
		return
	}

	wr.WithDataOrErr(utils.NullIfErr(wa.GetApp(uid)))
}

func (wa *WebAPI) HandleDeleteApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("app id can't be empty")
		return
	}

	wr.WithDataOrErr(nil, wa.DeleteApp(uid))
}

func (wa *WebAPI) HandleUpdateApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("app id can't be empty")
		return
	}

	// marshal app from body
	var app core.App
	if err := json.NewDecoder(r.Body).Decode(&app); err != nil {
		wr.WithCode(101).WithErrorf("decode app error: %s", err)
		return
	}

	// TODO:

	app.Secret = ""

	wr.WithDataOrErr(wa.UpdateApp(uid, &app))
}

// TODO: bind agent for app

func (wa *WebAPI) HandleListAgentsByApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("app id can't be empty")
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

	wr.WithDataOrErr(wa.ListAgentsByApp(uid, offset, limit))
}

func (wa *WebAPI) HandleListRecordsByApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("app id can't be empty")
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

	wr.WithDataOrErr(wa.ListRecordsByApp(uid, offset, limit))
}

func (wa *WebAPI) HandleAddAgentForApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("app id can't be empty")
		return
	}
	
	// TODO:
}

func (wa *WebAPI) HandleUpdateAgentForApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var appuid = mux.Vars(r)["app_uid"]
	if appuid == "" {
		wr.WithCode(200).WithErrorf("app id can't be empty")
		return
	}

	var agentuid = mux.Vars(r)["agent_uid"]
	if agentuid == "" {
		wr.WithCode(200).WithErrorf("agent id can't be empty")
		return
	}

	// TODO:
}

func (wa *WebAPI) HandleRemoveAgentFromApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var appuid = mux.Vars(r)["app_uid"]
	if appuid == "" {
		wr.WithCode(200).WithErrorf("app id can't be empty")
		return
	}

	var agentuid = mux.Vars(r)["agent_uid"]
	if agentuid == "" {
		wr.WithCode(200).WithErrorf("agent id can't be empty")
		return
	}

	// TODO:
}