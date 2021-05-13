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

const (
	OrderStatusPending = iota
	OrderStatusPaid
	OrderStatusExpired
	OrderStatusCanceled
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
	Model `json:"model,omitempty" yaml:"model"`

	AppID string `gorm:"index:app" json:"app_id,omitempty" yaml:"app_id"` // app id

	PreOrder PreOrder `gorm:"embedded;embeddedPrefix:o_" json:"pre_order,omitempty" yaml:"pre_order"`

	ExpiresIn int `json:"expires_in,omitempty" yaml:"expires_in"` // expiry time (seconds)

	QrData     string `json:"qr_data,omitempty" yaml:"qr_data"`           // qrcode data
	QrImageUrl string `json:"qr_image_url,omitempty" yaml:"qr_image_url"` // qrcode image url

	// sched unique(price-agent<device>-type)
	SchedAgentUID string `gorm:"index:sched,unique" json:"sched_agent_uid,omitempty" yaml:"sched_agent_uid"` // agent
	SchedPayType  string `gorm:"index:sched,unique" json:"sched_pay_type,omitempty" yaml:"sched_pay_type"`   // pay type
	SchedPrice    int    `gorm:"index:sched,unique" json:"sched_price,omitempty" yaml:"sched_price"`         // unit cent

	PayRecordUID string      `json:"-,omitempty" yaml:"-"`                                                  //
	Status       OrderStatus `json:"status,omitempty" yaml:"status"`                                        // order status
	PayRecord    *PayRecord  `gorm:"foreignKey:PayRecordUID" json:"pay_record,omitempty" yaml:"pay_record"` // pay record
}

type PreOrder struct {
	// custom order data
	Number      string `gorm:"index:pre_order_number" json:"number,omitempty" yaml:"number"` // pre order number
	Name        string `json:"name,omitempty" yaml:"name"`                                   // pre order name
	Price       int    `json:"price,omitempty" yaml:"price"`                                 // pre order price unit cent
	RedirectUrl string `json:"redirect_url,omitempty" yaml:"redirect_url"`                   // redirect url after success
	External    string `json:"external,omitempty" yaml:"external"`                           // external info, like user
}
