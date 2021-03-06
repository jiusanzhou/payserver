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

	"github.com/gorilla/mux"
	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/utils"
	"go.zoe.im/x/httputil"
)

func (wa *WebAPI) HandleCreateOrder(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	// TODO: auto invaild, check field

	rq := r.URL.Query()

	// take app id
	var appid = rq.Get("appid")
	if appid == "" {
		wr.WithCode(100).WithErrorf("appid can't be empty").Flush()
		return
	}

	// marshal preorder from body
	var preOrder core.PreOrder
	if err := json.NewDecoder(r.Body).Decode(&preOrder); err != nil {
		wr.WithCode(101).WithErrorf("decode order error: %s", err)
		return
	}

	// check price
	if preOrder.Price <= 0 {
		wr.WithCode(102).WithErrorf("order price must greatter than 0")
		return
	}

	// check pre order: number can't be empty
	if preOrder.Number == "" {
		wr.WithCode(103).WithErrorf("order number can't be empty")
		return
	}

	wr.WithDataOrErr(wa.CreateOrder(appid, rq.Get("method"), &preOrder))
}

func (wa *WebAPI) HandleGetOrder(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("order id can't be empty")
		return
	}

	wr.WithDataOrErr(utils.NullIfErr(wa.GetOrder(uid)))
}

func (wa *WebAPI) HandleGetOrderStatus(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("order id can't be empty")
		return
	}

	wr.WithDataOrErr(wa.GetOrderStatus(uid))
}

func (wa *WebAPI) HandleCancelOrder(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var uid = mux.Vars(r)["uid"]
	if uid == "" {
		wr.WithCode(200).WithErrorf("order id can't be empty").Flush()
		return
	}

	wr.WithDataOrErr(wa.CancelOrder(uid))
}
