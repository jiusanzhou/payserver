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
	"time"

	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/utils"
)

var (
	ErrOrderNumberExits     = errors.New("order number already exits")
	ErrUnsupportedPayMethod = errors.New("unsupported pay method")
	ErrAppNotFound          = errors.New("unknown app id")
	ErrPenddingOrderLimit   = errors.New("pendding order limit")
	ErrNoAviableAgent       = errors.New("no aviable agent")
	ErrSchedPriceBusy       = errors.New("sched price busy")
)

// selectAgentByWeight selects an agent based on weights
func selectAgentByWeight(agents []*core.Agent, weights []uint) *core.Agent {
	if len(agents) == 0 {
		return nil
	}
	if len(agents) == 1 {
		return agents[0]
	}

	// Calculate total weight
	var totalWeight uint
	for _, w := range weights {
		if w == 0 {
			w = 1
		}
		totalWeight += w
	}

	// Random selection
	r := uint(rand.Intn(int(totalWeight)))
	var cumulative uint
	for i, w := range weights {
		if w == 0 {
			w = 1
		}
		cumulative += w
		if r < cumulative {
			return agents[i]
		}
	}

	return agents[len(agents)-1]
}

func (s *Server) IsSupportedPayType(method string) bool {
	return core.IsSupportedPayType(method)
}

// CreateOrder create the order from backend service
func (s *Server) CreateOrder(appid, method string, preorder *core.PreOrder) (*core.Order, error) {

	// if method is empty, default to wechat
	if method == "" {
		method = string(core.PayTypeWeChat)
	}

	// validate pay method
	if !s.IsSupportedPayType(method) {
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

	// random choose an agent with weight
	var agents []*core.Agent
	var weights []uint
	for _, a := range app.Agents {
		if a.Status == core.AgentStatusNormal {
			agents = append(agents, a)
			// TODO: get weight from AppAgentBind, default to 1
			weights = append(weights, 1)
		}
	}

	if len(agents) == 0 {
		return nil, ErrNoAviableAgent
	}

	// weighted random selection
	agent := selectAgentByWeight(agents, weights)
	// TODO: log chooseen the agent

	// ok, let's generate the key, first search agent by appid
	// generate the <agent>-<type>-<price>
	// <floor> ... <ceil>
	// random to choose an agent for app and which is not busying(arrive the max pendding)

	// check which one is not exits
	// gen the prices array
	var found bool
	var price int
	var schedKey string

	s.Lock()
	for _, i := range utils.GenPriceFloats(app.PriceFloor, app.PriceCeil) {
		price = preorder.Price + i
		schedKey = fmt.Sprintf("%v-%v-%v", agent.UID, method, price)
		if _, ok := s.uniqueIDs[schedKey]; !ok {
			found = true
			s.uniqueIDs[schedKey] = true
			break
		}
	}
	s.Unlock()

	if !found {
		return nil, ErrSchedPriceBusy
	}

	// when to mark agent status to busy?
	// check agent if max pending, and try to set busy

	// ok, preorder, app, agent, price all ready, let's create order
	order := &core.Order{
		AppID:     appid,
		PreOrder:  *preorder,
		ExpiresIn: app.ExpireIn, // from app or query?
		// TODO: how to generate the QrData nad QrIamgeURL
		// get from agent's price qrcode table or generate auto
		SchedAgentUID: agent.UID,
		SchedPayType:  core.PayType(method),
		SchedPrice:    price,
		Status:        core.OrderStatusPending, // wait for paid
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
	// get order first to release schedKey
	order, err := s.store.GetOrder(uid)
	if err != nil {
		return nil, err
	}

	// only pending orders can be canceled
	if order.Status != core.OrderStatusPending {
		return order, nil
	}

	// release the schedKey
	schedKey := fmt.Sprintf("%v-%v-%v", order.SchedAgentUID, order.SchedPayType, order.SchedPrice)
	s.Lock()
	delete(s.uniqueIDs, schedKey)
	s.Unlock()

	// update status
	order.Status = core.OrderStatusCanceled
	return s.store.UpdateOrder(order)
}

// MatchOrderByRecord matches a pay record to a pending order
func (s *Server) MatchOrderByRecord(record *core.PayRecord) (*core.Order, error) {
	// generate schedKey from record
	schedKey := fmt.Sprintf("%v-%v-%v", record.AgentUID, record.Type, record.Amount)

	// check if schedKey exists
	s.RLock()
	exists := s.uniqueIDs[schedKey]
	s.RUnlock()

	if !exists {
		return nil, nil // no matching order
	}

	// find the pending order with this sched
	orders, err := s.store.ListOrders(0, 1,
		"sched_agent_uid = ? AND sched_pay_type = ? AND sched_price = ? AND status = ?",
		record.AgentUID, record.Type, record.Amount, core.OrderStatusPending)
	if err != nil || len(orders) == 0 {
		return nil, err
	}

	order := orders[0]

	// release schedKey
	s.Lock()
	delete(s.uniqueIDs, schedKey)
	s.Unlock()

	// update order status
	order.Status = core.OrderStatusPaid
	order.PayRecordUID = record.UID

	return s.store.UpdateOrder(order)
}

// ListOrders lists orders with optional filters
func (s *Server) ListOrders(offset, limit int, query ...interface{}) ([]*core.Order, error) {
	return s.store.ListOrders(offset, limit, query...)
}

// GetCallbackStatus returns callback info for an order
func (s *Server) GetCallbackStatus(orderUID string) (*core.CallbackLog, error) {
	return s.store.GetCallbackByOrder(orderUID)
}

// RetryCallback manually retries a failed callback
func (s *Server) RetryCallback(orderUID string) (*core.CallbackLog, error) {
	cb, err := s.store.GetCallbackByOrder(orderUID)
	if err != nil {
		return nil, err
	}

	// Reset for retry
	now := time.Now()
	cb.Status = core.CallbackStatusPending
	cb.NextAttempt = &now

	return s.store.UpdateCallback(cb)
}
