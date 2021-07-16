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

	"gorm.io/gorm"
)

// Model 通用模型
type Model struct {

	// required: true
	ID uint64 `json:"id" gorm:"primary_key;autoIncrement:true"`

	// required: true
	UID string `json:"uid" gorm:"primary_key;type:uuid"` // uuid?

	CreateAt  time.Time  `json:"create_at"`
	UpdatedAt time.Time  `json:"update_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty" gorm:"index"`
}

type SimpleModel struct {
	ID        uint64         `json:"id,omitempty" gorm:"primary_key;autoIncrement:true" yaml:"id"`
	CreatedAt time.Time      `json:"created_at,omitempty" yaml:"created_at"`
	DeletedAt gorm.DeletedAt `json:"deleted_at,omitempty" yaml:"deleted_at"`
}
