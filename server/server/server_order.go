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
	"fmt"
	"math/rand"

	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/utils"
)

var (
	ErrOrderNumberExits = errors.New("order number already exits")
	ErrUnsupportedPayMethod = errors.New("unsupported pay method")
	ErrAppNotFound = errors.New("unknown app id")
	ErrPenddingOrderLimit = errors.New("pendding order limit")
	ErrNoAviableAgent = errors.New("no aviable agent")
	ErrSchedPriceBusy = errors.New("sched price busy")
)

func (s *Server) IsSupportedPayType(method string) bool {
	return core.IsSupportedPayType(method)
}

// CreateOrder create the order from backend service
func (s *Server) CreateOrder(appid, method string, preorder *core.PreOrder) (*core.Order, error) {

	// TODO: if method is empty, choose a available one
	// if method is not empty, we should check first
	if method != "" || !s.IsSupportedPayType(method) {
		return nil, ErrUnsupportedPayMethod
	}

	// get app with appid first, can make sure app exits
	app, err := s.store.GetApp(appid)
	if err != nil {
		return nil, ErrAppNotFound
	}

	// check the max pendding order (and global) ?
	// get current waitting pay price with all agents<bind with app>
	// select * from order where status == ? AND agent_uid in (select uid from app_agent where app_id == ?)
	// TODO: use model state with auto sync to db
	ords, err := s.store.GetOrdersByApp(appid, core.OrderStatusPending)
	if err != nil {
		return nil, err
	}

	if len(ords) >= app.MaxPenddingOrder {
		return nil, ErrPenddingOrderLimit
	}

	// check <appid>-<order-number> if exits, must make sure number is unique
	_, err = s.store.GetOrderByAppAndNumber(appid, preorder.Number)
	// TODO: check IsNotFound(err)
	if err == nil {
		return nil, ErrOrderNumberExits
	}

	// random choose an agent
	var agents []*core.Agent
	for _, a := range app.Agents {
		if a.Status == core.AgentStatusNormal {
			agents = append(agents, a)
		}
	}
	
	if len(agents) == 0 {
		return nil, ErrNoAviableAgent
	}

	// TODO: with weight ?
	// random choose a agent
	agent := agents[rand.Intn(len(agents))]
	// TODO: log chooseen the agent

	// ok, let's generate the key, first search agent by appid
	// generate the <agent>-<type>-<price>
	// <floor> ... <ceil>
	// random to choose an agent for app and which is not busying(arrive the max pendding)

	prefix := fmt.Sprintf("%v-%v", agent.UID, method)
	
	// check which one is not exits
	// gen the prices array
	var found bool
	var price int

	s.Lock()
	for _, i := range utils.GenPriceFloats(app.PriceFloor, app.PriceCeil) {
		price = i + preorder.Price
		key := fmt.Sprintf("%v-%v", prefix, price)
		if _, ok := s.uniqueIDs[key]; !ok {
			found = true
			s.uniqueIDs[key] = true
			found = true
		}
	}
	s.Unlock()

	if (!found) {
		return nil, ErrSchedPriceBusy
	}

	// when to mark agent status to busy?
	// check agent if max pending, and try to set busy

	// ok, preorder, app, agent, price all ready, let's create order
	order := &core.Order{
		AppID: appid,
		PreOrder: *preorder,
		ExpiresIn: app.ExpireIn, // from app or query?
		// TODO: how to generate the QrData nad QrIamgeURL
		// get from agent's price qrcode table or generate auto
		SchedAgentUID: agent.UID,
		SchedPayType: core.PayType(method),
		SchedPrice: price,
		Status: core.OrderStatusPending, // wait for paid
	}

	return s.store.CreateOrder(order)
}

func (s *Server) GetOrder(uid string) (*core.Order, error) {
	// some field we need to hidden
	// which field need to be hidden?
	or, err := s.store.GetOrder(uid)
	// nothing shoul be hidden
	// if or != nil {
	// }
	return or, err
}

func (s *Server) GetOrderStatus(uid string) (core.OrderStatus, error) {
	// get status of order
	// means we only return status
	or, err := s.store.GetOrder(uid)
	if err != nil {
		return core.OrderStatusUnknown, err
	}

	return or.Status, nil
}

func (s *Server) CancelOrder(uid string) (*core.Order, error) {

	// cancel the order, just set the tatus to cancled
	// adn notify clients
	return s.store.UpdateOrder(&core.Order{
		Model: core.Model{UID: uid},
		// set the status
		Status: core.OrderStatusExpired, // make sure only update this field
	})
	// TODO: notify all clients
}
