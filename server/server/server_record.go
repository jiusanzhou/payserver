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

import (
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"go.zoe.im/payserver/server/core"
)

func (s *Server) CreateRecord(rd *core.PayRecord) (*core.PayRecord, error) {
	// save record first
	record, err := s.store.CreateRecord(rd)
	if err != nil {
		return nil, err
	}

	// try to match with pending order
	order, err := s.MatchOrderByRecord(record)
	if err != nil {
		log.Printf("match order error: %v", err)
	}

	// if matched, trigger callback
	if order != nil {
		go s.notifyCallback(order, record)
	}

	return record, nil
}

// notifyCallback sends webhook notification to app callback URL
func (s *Server) notifyCallback(order *core.Order, record *core.PayRecord) {
	app, err := s.store.GetApp(order.AppID)
	if err != nil {
		log.Printf("get app for callback error: %v", err)
		return
	}

	if app.CallbackURL == "" {
		return
	}

	// build callback payload
	payload := fmt.Sprintf(`{"order_id":"%s","number":"%s","status":"paid","amount":%d,"pay_type":"%s","record_id":"%s","timestamp":"%s"}`,
		order.UID,
		order.PreOrder.Number,
		order.SchedPrice,
		order.SchedPayType,
		record.UID,
		time.Now().Format(time.RFC3339),
	)

	// retry 3 times
	for i := 0; i < 3; i++ {
		resp, err := http.Post(app.CallbackURL, "application/json", strings.NewReader(payload))
		if err == nil && resp.StatusCode >= 200 && resp.StatusCode < 300 {
			resp.Body.Close()
			log.Printf("callback success: order=%s app=%s", order.UID, app.Name)
			return
		}
		if resp != nil {
			resp.Body.Close()
		}
		log.Printf("callback failed (attempt %d): order=%s err=%v", i+1, order.UID, err)
		time.Sleep(time.Duration(i+1) * time.Second)
	}
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
