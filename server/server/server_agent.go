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
func (s *Server) PrepareAgent(agent *core.Agent) (*core.RegisterAgentTicket, error) {
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

	agent.Ticket = ticket
	agent.Status = core.AgentStatusPendding

	_, err = s.store.CreateAgent(agent)

	if err != nil {
		log.Println("create pendding agent error:", err)
		return nil, err
	}

	return &core.RegisterAgentTicket{
		Name:    s.c.Name,
		Host:    s.c.Host,
		Version: s.c.Version,

		Ticket: ticket,
	}, nil
}

func (s *Server) RegisterAgent(a *core.Agent) (*core.Agent, error) {
	// check ticket if exits
	pa, err := s.store.GetAgentByTicket(a.Ticket)
	if err != nil {
		log.Println("can't found the ticket")
		return nil, err
	}

	// if we can find one device with ticket
	// just return error
	if pa.Status != core.AgentStatusPendding {
		// that means we have be registed with this ticket
		return nil, errors.New("ticket has been used")
	}

	// copy data and save
	pa.DeviceID = a.DeviceID
	pa.DeviceInfo = a.DeviceInfo
	pa.PayTypes = a.PayTypes
	pa.External = a.External

	// set status to normal at register
	pa.Status = core.AgentStatusNormal

	// heartbeat at register time
	pa.HeartbeatAt = time.Now()

	return s.store.UpdateAgent(pa)
}

func (s *Server) UpdateAgent(id string, agent *core.Agent) (*core.Agent, error) {
	agent.UID = id
	return s.store.UpdateAgent(agent)
}

func (s *Server) GetAgent(id string) (*core.Agent, error) {
	return s.store.GetAgent(id)
}

func (s *Server) DeleteAgent(id string) error {
	return s.store.DeleteAgent(id)
}

func (s *Server) ListAgents(offset int, limit int) ([]*core.Agent, error) {
	return s.store.ListAgents(offset, limit)
}

func (s *Server) ListAgentsByApp(id string, offset int, limit int) ([]*core.Agent, error) {
	return s.store.ListAgents(offset, limit, "agent_uid = ?", id)
}
