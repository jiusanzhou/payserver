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

	"github.com/gorilla/mux"
	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/utils"
	"go.zoe.im/x/httputil"
)

// Record means PayRecord alse named Transaction

func (wa *WebAPI) HandleCreateRecord(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var rd core.PayRecord
	if err := json.NewDecoder(r.Body).Decode(&rd); err != nil {
		wr.WithCode(101).WithErrorf("decode record error: %s", err)
		return
	}

	// should we invial the data?

	// ok, let's just save it
	wr.WithDataOrErr(wa.CreateRecord(&rd))
}

func (wa *WebAPI) HandleGetRecord(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("record id can't be empty")
		return
	}

	wr.WithDataOrErr(utils.NullIfErr(wa.GetRecord(uid)))
}

func (wa *WebAPI) HandleListRecords(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	q := r.URL.Query()

	method := q.Get("method")
	if !core.IsSupportedPayType(method) {
		wr.WithCode(201).WithErrorf("unsupported pay method")
		return
	}

	offset := 0
	limit := 10

	if o, err := strconv.Atoi(q.Get("offset")); err == nil {
		offset = o
	}

	if l, err := strconv.Atoi(q.Get("limit")); err == nil && l < 50 {
		limit = l
	}

	// query args
	wr.WithDataOrErr(wa.ListRecords(core.PayType(method), offset, limit))
}

// won't privder delete
