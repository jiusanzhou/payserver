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

func (d driver) CreateRecord(rd *core.PayRecord) (*core.PayRecord, error) {
	return rd, d.Create(rd).Error
}

func (d driver) GetRecord(uid string) (*core.PayRecord, error) {
	var rd core.PayRecord
	return &rd, d.Where("uid = ?", uid).First(&rd).Error
}

func (d driver) ListRecords(offset, limit int, query ...interface{}) ([]*core.PayRecord, error) {
	var rs []*core.PayRecord
	return rs, d.Where(query).Offset(offset).Limit(limit).Find(&rs).Error
}

func (d driver) UpdateRecord(rd *core.PayRecord) (*core.PayRecord, error) {
	// must with uid
	if rd.UID == "" {
		return nil, store.ErrMissObjectID
	}

	return rd, d.Model(rd).Where("uid = ?", rd.UID).Updates(rd).Error
}

func (d driver) DeleteRecord(uid string) error {
	if uid == "" {
		return store.ErrMissObjectID
	}

	return d.Where("uid = ?", uid).Delete(&core.PayRecord{}).Error
}
