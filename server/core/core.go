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
)

type OrderStatus int


var (
	_OrderStatusStrings = []string{"pending", "paid", "expired", "canceled"}
)

func (o OrderStatus) String() string {
	return _OrderStatusStrings[o]
}

// Order create a order for pay 订单
type Order struct {
	Model `json:"model,omitempty" yaml:"model"`

	AppID string `json:"app_id,omitempty" yaml:"app_id"` // 应用ID

	PreOrder PreOrder `gorm:"embedded;embeddedPrefix:o_" json:"pre_order,omitempty" yaml:"pre_order"`

	ExpiresIn   int     `json:"expires_in,omitempty" yaml:"expires_in"`     // 过期时间(秒)
	QrData      string  `json:"qr_data,omitempty" yaml:"qr_data"`           // qrcode data
	QrImageUrl  string  `json:"qr_image_url,omitempty" yaml:"qr_image_url"` // qrcode image url
	SignedPrice float32 `json:"signed_price,omitempty" yaml:"signed_price"` // 被分配到的唯一价格

	PayRecordUID string      `json:"-,omitempty" yaml:"-"`
	Status       OrderStatus `json:"status,omitempty" yaml:"status"`                                        // 订单状态
	PayRecord    *Record     `gorm:"foreignKey:PayRecordUID" json:"pay_record,omitempty" yaml:"pay_record"` // 支付记录
}

type PreOrder struct {
	// 外部订单数据
	ID          string  `json:"id,omitempty" yaml:"id"`                     // 订单号
	Name        string  `json:"name,omitempty" yaml:"name"`                 // 订单名
	Price       float32 `json:"price,omitempty" yaml:"price"`               // 订单价格 0.00
	RedirectUrl string  `json:"redirect_url,omitempty" yaml:"redirect_url"` // 支付成功后的重定向地址
	Extension   string  `json:"extension,omitempty" yaml:"extension"`       // 其他额外信息
}

// Record -> Order 收款记录
type Record struct {
	Model `json:"model,omitempty" yaml:"model"`

	// belong to who?
	Channel   string  `json:"channel,omitempty" yaml:"channel"` // 区分多个账号 xxx
	PayType   string  `json:"type,omitempty" yaml:"type"`       // wechat / alipay
	PayAmount float32 `json:"amount,omitempty" yaml:"amount"`   // received money
}

// Qrcode ? 二维码
