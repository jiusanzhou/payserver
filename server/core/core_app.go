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

// App is the application register in the server to create order
type App struct {
	Model

	Name        string `gorm:"index,unique" json:"name" yaml:"name"` // app name
	Description string `json:"description" yaml:"description"`       // description

	CallbackURL string `json:"callback_url" yaml:"callback_url"` // notify the app server
	Secret      string `json:"secret" yaml:"secret"`             // secret for app
	AESKey      string `json:"aes_key" yaml:"aes_key"`           // aes key for data encode

	// Configuration for app
	PriceFloor       int `json:"price_floor" yaml:"price_floor"` // price can be decrease to, default 100
	PriceCeil        int `json:"price_ceil" yaml:"price_ceil"`   // price can be increase to, default 0
	ExpireIn         int `json:"expire_in" yaml:"expire_in"`
	MaxPenddingOrder int `json:"max_pendding_order" yaml:"max_pendding_order"`

	// TODO: with weight?
	Agents []*Agent `gorm:"many2many:app_agents;ForeignKey:uid;References:uid" json:"agents" yaml:"agents"`

	// TODO: belong to user
	UserUID string `json:"user_uid" yaml:"user_uid"`
	User    *User  `gorm:"foreignKey:UserUID" json:"user" yaml:"user"`
}

// BeforeCreate ...
func (act *App) BeforeCreate(tx *gorm.DB) error {
	act.UID = uuid.New().String()

	t := time.Now()

	act.CreateAt = t
	act.UpdatedAt = t

	return nil
}

// TODO: customize AppAgent struct add Model<CreateAt> and weight field
type AppAgentBind struct {
	SimpleModel
	AppUID   string `gorm:"primaryKey" json:"app_uid,omitempty" yaml:"app_uid"`
	AgentUID string `gorm:"primaryKey" json:"agent_uid,omitempty" yaml:"agent_uid"`
	Weight   uint   `json:"weight,omitempty" yaml:"weight"`
}
