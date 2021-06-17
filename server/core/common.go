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

// Model 通用模型
type Model struct {

	// required: true
	ID int `json:"id" gorm:"primary_key"`

	// required: true
	UID string `json:"uid" gorm:"primary_key"` // uuid?

	CreateAt  time.Time  `json:"create_at"`
	UpdatedAt time.Time  `json:"update_at"`
	DeletedAt  *time.Time `json:"deleted_at,omitempty" gorm:"index"`
}

// BeforeCreate ...
func (act *App) BeforeCreate(tx *gorm.DB) error {
	act.UID = uuid.New().String()

	t := time.Now()

	act.CreateAt = t
	act.UpdatedAt = t

	return nil
}

// BeforeCreate ...
func (act *Agent) BeforeCreate(tx *gorm.DB) error {
	act.UID = uuid.New().String()

	t := time.Now()

	act.CreateAt = t
	act.UpdatedAt = t

	return nil
}

// BeforeCreate ...
func (act *Order) BeforeCreate(tx *gorm.DB) error {
	act.UID = uuid.New().String()

	t := time.Now()

	act.CreateAt = t
	act.UpdatedAt = t

	return nil
}

// BeforeCreate ...
func (act *PayRecord) BeforeCreate(tx *gorm.DB) error {
	act.UID = uuid.New().String()

	t := time.Now()

	act.CreateAt = t
	act.UpdatedAt = t

	return nil
}
