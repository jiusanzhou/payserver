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
	"errors"
	"log"
	"time"

	"github.com/google/uuid"
	"go.zoe.im/payserver/server/core"
)

var (
	ErrLimitPendingAgent = errors.New("pending agent count limit")
)

// PrepareAgent return server information and code for register
func (s *Server) PrepareAgent() (interface{}, error) {
	// generate a ticket and store in the store, for agent register
	// if pending count greatter then max, just return error
	n, err := s.store.CountPenddingAgents()
	if err != nil {
		log.Println("count pendding agents error:", err)
		return nil, err
	}

	if n >= s.c.MaxPenddingAgent {
		return nil, ErrLimitPendingAgent
	}

	// let's generate a pending agent, and store to database
	ticket := uuid.New().String()

	_, err = s.store.CreateAgent(&core.Agent{
		Ticket: ticket,
		Status: core.AgentStatusPendding,
	})

	if err != nil {
		log.Println("create pendding agent error:", err)
		return nil, err
	}

	return map[string]interface{}{
		"ticket": ticket,
		"server": s.Name(),
	}, nil
}

func (s *Server) RegisterAgent(a *core.Agent) (*core.Agent, error) {
	// check ticket if exits
	pa, err := s.store.GetAgentByTicket(a.Ticket)
	if err != nil {
		log.Println("can't found the ticket")
		return nil, err
	}

	// copy data and save
	pa.DeviceID = a.DeviceID
	pa.DeviceInfo = a.DeviceInfo
	pa.PayTypes = a.PayTypes
	pa.External = a.External

	pa.Status = core.AgentStatusNormal

	// heartbeat at register time
	pa.HeartbeatAt = time.Now()

	return s.store.UpdateAgent(pa)
}

func (s *Server) ListAgents() ([]*core.Agent, error) {
	// TODO: add filter?
	return s.store.ListAgents()
}
