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

	"go.zoe.im/payserver/server/core"
)

var (
	ErrOrderNumberExits = errors.New("order number already exits")
	ErrUnsupportedPayMethod = errors.New("unsupported pay method")
)

func (s *Server) IsSupportedPayType(method string) bool {
	return core.IsSupportedPayType(method)
}

// CreateOrder create the order from backend service
func (s *Server) CreateOrder(appid, method string, preorder *core.PreOrder) (*core.Order, error) {
	// check <appid>-<order-number> if exits
	_, err := s.store.GetOrderByAppAndNumber(appid, preorder.Number)
	// check IsNotFound(err)
	if err == nil {
		return nil, ErrOrderNumberExits
	}

	// if method is not empty, we should check first
	if method != "" && !s.IsSupportedPayType(method) {
		return nil, ErrUnsupportedPayMethod
	}

	// check the max pendding order (should with app) ?

	// if method is empty, choose a available one

	// get current waitting pay price with all agents<bind with app>
	// select * from order where status == ? AND agent_uid in (select uid from app_agent where app_id == ?)
	ords, err := s.store.GetOrdersByApp(appid, core.OrderStatusPending)
	if err != nil {
		return nil, err
	}

	_ = ords

	// ok, let's generate the key, first search agent by appid
	// generate the <agent>-<type>-<price>
	
	// check which one is not exits

	// TODO: 

	return nil, nil
}

func (s *Server) GetOrder(uid string) (*core.Order, error) {
	// some field we need to hidden
	return s.store.GetOrder(uid)
}

func (s *Server) GetOrderStatus(uid string) (*core.Order, error) {

	return nil, nil
}

func (s *Server) CancelOrder(uid string) (*core.Order, error) {

	return nil, nil
}
