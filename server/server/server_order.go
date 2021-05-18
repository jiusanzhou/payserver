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

// CreateOrder create the order from backend service
func (s *Server) CreateOrder(appid string, preorder *core.PreOrder) (*core.Order, error) {
	// generate the <agent>-<type>-<price>
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
