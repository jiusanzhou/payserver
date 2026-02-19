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
	"net/http"

	"github.com/gorilla/mux"
	"go.zoe.im/x/httputil"
)

func (wa *WebAPI) HandleGetCallbackStatus(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var orderUID = mux.Vars(r)["uid"]
	if orderUID == "" {
		wr.WithCode(400).WithErrorf("order id can't be empty")
		return
	}

	wr.WithDataOrErr(wa.GetCallbackStatus(orderUID))
}

func (wa *WebAPI) HandleRetryCallback(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer wr.Flush()

	var orderUID = mux.Vars(r)["uid"]
	if orderUID == "" {
		wr.WithCode(400).WithErrorf("order id can't be empty")
		return
	}

	wr.WithDataOrErr(wa.RetryCallback(orderUID))
}
