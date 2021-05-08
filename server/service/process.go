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

package service

import "go.zoe.im/payserver/server/core"

// 创建订单
// 分配余额

// 设备(代表账号) + type + 金额 => primary

// app 与 设备 多对多
// app

// user no need!!!

func (s *Server) CreateOrder(preorder *core.PreOrder) (*core.Order, error) {

	return nil, nil
}

func (s *Server) GetOrder(uid string) (*core.Order, error) {

	return nil, nil
}

func (s *Server) GetOrderStatus(uid string) (*core.Order, error) {

	return nil, nil
}

func (s *Server) CancelOrder(preorder *core.PreOrder) (*core.Order, error) {

	return nil, nil
}