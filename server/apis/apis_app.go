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

	"go.zoe.im/x/httputil"
)

func (wa *WebAPI) HandleListApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

func (wa *WebAPI) HandleCreateApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

func (wa *WebAPI) HandleGetApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

func (wa *WebAPI) HandleDeleteApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

func (wa *WebAPI) HandleUpdateApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

func (wa *WebAPI) HandleListAgentsByApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}

func (wa *WebAPI) HandleListRecordsByApp(w http.ResponseWriter, r *http.Request) {
	wr := httputil.NewResponse(w)
	defer r.Body.Close()

	wr.Flush()
}
