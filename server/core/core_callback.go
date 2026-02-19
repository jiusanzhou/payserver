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
	CallbackStatusPending = iota + 1
	CallbackStatusSuccess
	CallbackStatusFailed
)

type CallbackStatus int

var _callbackStatusStrings = []string{"", "pending", "success", "failed"}

func (s CallbackStatus) String() string {
	if int(s) < len(_callbackStatusStrings) {
		return _callbackStatusStrings[s]
	}
	return "unknown"
}

// CallbackLog records webhook delivery attempts
type CallbackLog struct {
	Model

	OrderUID     string         `gorm:"index" json:"order_uid" yaml:"order_uid"`
	AppID        string         `gorm:"index" json:"app_id" yaml:"app_id"`
	CallbackURL  string         `json:"callback_url" yaml:"callback_url"`
	Payload      string         `json:"payload" yaml:"payload"`
	Status       CallbackStatus `gorm:"index" json:"status" yaml:"status"`
	Attempts     int            `json:"attempts" yaml:"attempts"`
	MaxAttempts  int            `json:"max_attempts" yaml:"max_attempts"`
	LastError    string         `json:"last_error" yaml:"last_error"`
	LastResponse string         `json:"last_response" yaml:"last_response"`
	LastAttempt  *time.Time     `json:"last_attempt" yaml:"last_attempt"`
	NextAttempt  *time.Time     `gorm:"index" json:"next_attempt" yaml:"next_attempt"`
}

// BeforeCreate ...
func (c *CallbackLog) BeforeCreate(tx *gorm.DB) error {
	c.UID = uuid.New().String()
	t := time.Now()
	c.CreateAt = t
	c.UpdatedAt = t
	return nil
}

// RetryIntervals defines exponential backoff intervals (in seconds)
// 15s, 30s, 60s, 120s, 240s
var RetryIntervals = []int{15, 30, 60, 120, 240}

const MaxRetryAttempts = 5

// CalculateNextRetry returns the next retry time based on attempt number
func CalculateNextRetry(attempt int) *time.Time {
	if attempt >= MaxRetryAttempts {
		return nil
	}
	interval := RetryIntervals[attempt]
	next := time.Now().Add(time.Duration(interval) * time.Second)
	return &next
}

// ShouldRetry checks if callback should be retried
func (c *CallbackLog) ShouldRetry() bool {
	return c.Status == CallbackStatusPending && c.Attempts < c.MaxAttempts
}
