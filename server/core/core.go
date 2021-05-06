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

import "time"

// Order create a order for pay 订单
type Order struct {
	Model `json:"model,omitempty" yaml:"model"`

	AID string `json:"aid,omitempty" yaml:"aid"` // 应用ID

	OID          string  `json:"oid,omitempty" yaml:"oid"`                   // 订单ID
	OName        string  `json:"o_name,omitempty" yaml:"o_name"`             // 订单名
	OPrice       float32 `json:"o_price,omitempty" yaml:"o_price"`           // 订单价格 0.00
	ORedirectUrl string  `json:"redirect_url,omitempty" yaml:"redirect_url"` // 支付成功后的重定向地址
	OExtension   string  `json:"extension,omitempty" yaml:"extension"`       // 其他额外星系

	SignedPrice float32 `json:"signed_price,omitempty" yaml:"signed_price"` // 唯一价格
	Status      int     `json:"status,omitempty" yaml:"status"`             // 订单状态 0 unpaid, 1 paid, -1 expiry
}

// Record -> Order 收款记录
type Record struct {
	Model

	OType        string  `json:"o_type,omitempty" yaml:"o_type"`             // wechat / alipay
}

// Model for basic
type Model struct {
	ID        string     `gorm:"primary_key" json:"id,omitempty" yaml:"id"`
	CreatedAt time.Time  `json:"created_at,omitempty" yaml:"created_at"`
	UpdatedAt time.Time  `json:"updated_at,omitempty" yaml:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty" yaml:"deleted_at"`
}
