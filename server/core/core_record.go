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

package core

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PayType string

var (
	PayTypeWeChat PayType = "wechat"
	PayTypeAlipay PayType = "alipay"
	PayTypeAll    PayType = ""

	_supportedPayTypes = map[PayType]bool{
		PayTypeAlipay: true,
		PayTypeWeChat: true,

		// just for query
		PayTypeAll: true,
	}
)

func IsSupportedPayType(method string) bool {
	_, ok := _supportedPayTypes[PayType(method)]
	return ok
}

// PayRecord -> Order 收款记录
type PayRecord struct {
	Model

	// use device id or device uid,  just use uid, make sure we register at first
	AgentUID string  `json:"agent_uid" yaml:"agent_uid"`
	Type     PayType `json:"type" yaml:"type"`     // wechat / alipay
	Number   string  `json:"number" yaml:"number"` // platform number
	Amount   int     `json:"amount" yaml:"amount"` // received money unit cent

	Timestamp time.Time `json:"timestamp" yaml:"timestamp"` // agent local time

	AccountUID string  `json:"account_uid" yaml:"account_uid"`
	Account    Account `gorm:"foreignKey:AccountUID" json:"account" yaml:"account"`

	// TODO: add more field, like no.
	// TODO: in the future, we can add action to scrape the record detail for agent app.

	External string `json:"external" yaml:"external"`
}

// BeforeCreate ...
func (act *PayRecord) BeforeCreate(tx *gorm.DB) error {
	act.UID = uuid.New().String()

	t := time.Now()

	act.CreateAt = t
	act.UpdatedAt = t

	return nil
}
