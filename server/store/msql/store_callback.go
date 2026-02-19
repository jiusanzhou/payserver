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
	"time"

	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/store"
)

func (d *driver) CreateCallback(cb *core.CallbackLog) (*core.CallbackLog, error) {
	return cb, d.Create(cb).Error
}

func (d *driver) UpdateCallback(cb *core.CallbackLog) (*core.CallbackLog, error) {
	if cb.UID == "" {
		return nil, store.ErrMissObjectID
	}
	return cb, d.Model(cb).Where("uid = ?", cb.UID).Updates(cb).Error
}

func (d *driver) GetCallback(uid string) (*core.CallbackLog, error) {
	var cb core.CallbackLog
	return &cb, d.Where("uid = ?", uid).First(&cb).Error
}

func (d *driver) GetCallbackByOrder(orderUID string) (*core.CallbackLog, error) {
	var cb core.CallbackLog
	return &cb, d.Where("order_uid = ?", orderUID).Order("created_at DESC").First(&cb).Error
}

func (d *driver) ListPendingCallbacks(limit int) ([]*core.CallbackLog, error) {
	var cbs []*core.CallbackLog
	now := time.Now()
	return cbs, d.Where("status = ? AND next_attempt <= ?", core.CallbackStatusPending, now).
		Order("next_attempt ASC").
		Limit(limit).
		Find(&cbs).Error
}

func (d *driver) ListCallbacksByOrder(orderUID string) ([]*core.CallbackLog, error) {
	var cbs []*core.CallbackLog
	return cbs, d.Where("order_uid = ?", orderUID).Order("created_at DESC").Find(&cbs).Error
}
