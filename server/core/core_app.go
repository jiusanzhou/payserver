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

// App is the application register in the server to create order
type App struct {
	Model `json:"model,omitempty" yaml:"model"`

	Name        string `json:"name,omitempty" yaml:"name"`               // app name
	Description string `json:"description,omitempty" yaml:"description"` // description

	PriceFloor int `json:"price_floor,omitempty" yaml:"price_floor"` // price can be decrease to, default 100
	PriceCeil  int `json:"price_ceil,omitempty" yaml:"price_ceil"`   // price can be increase to, default 0

	CallbackURL string `json:"callback_url,omitempty" yaml:"callback_url"` // notify the app server
	Secret      string `json:"secret,omitempty" yaml:"secret"`             // secret for app
	AESKey      string `json:"aes_key,omitempty" yaml:"aes_key"`           // aes key for data encode

	Agents []*Agent `gorm:"many2many:app_agents;" json:"agents,omitempty" yaml:"agents"`

	// belong to user
}

// TODO: customize AppAgent struct add Model<CreateAt> field