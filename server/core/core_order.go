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

const (
	OrderStatusPending  = iota + 1 // wait for paid
	OrderStatusPaid                // paid
	OrderStatusExpired             // expired
	OrderStatusCanceled            //canceled
	OrderStatusUnknown
)

type OrderStatus int

var (
	_OrderStatusStrings = []string{"pending", "paid", "expired", "canceled", "unknown"}
)

func (o OrderStatus) String() string {
	return _OrderStatusStrings[o]
}

// Order create a order for pay
type Order struct {
	Model

	AppID    string   `gorm:"index:pre_app_number,unique" json:"app_id" yaml:"app_id"`
	PreOrder PreOrder `gorm:"embedded;embeddedPrefix:o_" json:"pre_order" yaml:"pre_order"`

	ExpiresIn int `json:"expires_in" yaml:"expires_in"` // expiry time (seconds)

	QrData     string `json:"qr_data" yaml:"qr_data"`           // qrcode data
	QrImageUrl string `json:"qr_image_url" yaml:"qr_image_url"` // qrcode image url

	// sched unique(price-agent<device>-type)
	SchedAgentUID string  `gorm:"index:sched,unique" json:"sched_agent_uid" yaml:"sched_agent_uid"` // agent
	SchedPayType  PayType `gorm:"index:sched,unique" json:"sched_pay_type" yaml:"sched_pay_type"`   // pay type
	SchedPrice    int     `gorm:"index:sched,unique" json:"sched_price" yaml:"sched_price"`         // unit cent

	PayRecordUID string      `json:"-" yaml:"-"`                                                  //
	Status       OrderStatus `json:"status" yaml:"status"`                                        // order status
	PayRecord    *PayRecord  `gorm:"foreignKey:PayRecordUID" json:"pay_record" yaml:"pay_record"` // pay record
}

// BeforeCreate ...
func (act *Order) BeforeCreate(tx *gorm.DB) error {
	act.UID = uuid.New().String()

	t := time.Now()

	act.CreateAt = t
	act.UpdatedAt = t

	return nil
}

type PreOrder struct {
	// custom order data
	Number      string `gorm:"index:pre_app_number,unique" json:"number" yaml:"number"` // pre order number
	Name        string `json:"name" yaml:"name"`                                        // pre order name
	Price       int    `json:"price" yaml:"price"`                                      // pre order price unit cent
	RedirectUrl string `json:"redirect_url" yaml:"redirect_url"`                        // redirect url after success
	External    string `json:"external" yaml:"external"`                                // external info, like user
}
