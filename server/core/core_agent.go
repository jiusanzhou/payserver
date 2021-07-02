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

type AgentStatus int

const (
	AgentStatusNormal = iota
	AgentStatusOffline
	AgentStatusDisable
	AgentStatusPendding
	AgentStatusBusy
	AgentStatusUnknown
)

var (
	_AgentStatusStrings = []string{"normal", "offline", "disable", "pendding", "busy", "unknown"}
)

func (o AgentStatus) String() string {
	return _AgentStatusStrings[o]
}

type Agent struct {
	Model

	// imei or something else
	DeviceID string `gorm:"index:device,unique" json:"device_id,omitempty" yaml:"device_id"`
	// [] support pay types: wechat alipay
	PayTypes    string      `json:"pay_types,omitempty" yaml:"pay_types"`
	HeartbeatAt time.Time   `json:"heartbeat_at,omitempty" yaml:"heartbeat_at"`
	Status      AgentStatus `json:"status,omitempty" yaml:"status"`

	// for register a agent
	Ticket string `gorm:"index" json:"ticket,omitempty" yaml:"ticket"`

	// {}
	DeviceInfo string `json:"device_info,omitempty" yaml:"device_info"`

	// agent version or something else
	// {}
	External string `json:"external,omitempty" yaml:"external"`

	// Provider bind to device provider user
}

// bind agent<find by user first> with app
