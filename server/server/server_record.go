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

package server

import "go.zoe.im/payserver/server/core"

func (s *Server) CreateRecord(rd *core.PayRecord) (*core.PayRecord, error) {
	return s.store.CreateRecord(rd)
}

func (s *Server) GetRecord(uid string) (*core.PayRecord, error) {
	return s.store.GetRecord(uid)
}

func (s *Server) ListRecords(method core.PayType, offset, limit int) ([]*core.PayRecord, error) {
	return s.store.ListRecords(offset, limit, "type = ?", method)
}

func (s *Server) ListRecordsByAgent(uid string, offset, limit int) ([]*core.PayRecord, error) {
	return s.store.ListRecords(offset, limit, "sched_agent_uid = ?", uid)
}

func (s *Server) ListRecordsByApp(uid string, offset, limit int) ([]*core.PayRecord, error) {
	return s.store.ListRecords(offset, limit, "app_id = ?", uid)
}
