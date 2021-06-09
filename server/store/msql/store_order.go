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

package msql

import (
	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/store"
)

func (d driver) CreateOrder(or *core.Order) (*core.Order, error) {
	return or, d.Create(or).Error
}

func (d driver) UpdateOrder(or *core.Order) (*core.Order, error) {
	// must with uid
	if or.UID == "" {
		return nil, store.ErrMissObjectID
	}

	return or, d.Model(or).Where("uid = ?", or.UID).Updates(or).Error
}

func (d driver) DeleteOrder(id string) error {
	if id == "" {
		return store.ErrMissObjectID
	}

	return d.Where("uid = ?", id).Delete(&core.Order{}).Error
}

func (d driver) GetOrder(id string) (*core.Order, error) {
	var or core.Order
	return &or, d.Where("uid = ? AND delete_at == null", id).First(&or).Error
}

func (d driver) GetOrderByAppAndNumber(appid string, num string) (*core.Order, error) {
	// by order id, create from outside
	var or core.Order
	return &or, d.Where("app_id = ? AND o_number = ? AND delete_at == null", appid, num).First(&or).Error
}

func (d driver) GetOrdersByApp(appid string, statuss ...core.OrderStatus) ([]*core.Order, error) {

	return nil, store.ErrNoImplement
}