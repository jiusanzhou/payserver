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

package config

import "go.zoe.im/payserver/server/core"

type Config struct {
	Addr            string `json:"addr,omitempty" yaml:"addr"`
	DB              string `json:"db,omitempty" yaml:"db"`
	Debug           bool   `json:"debug,omitempty" yaml:"debug"`
	HTTPAllowOrigin string `json:"http_allow_origin,omitempty" yaml:"http_allow_origin"`

	PriceFloor int `json:"price_floor,omitempty" yaml:"price_floor"`
	PriceCeil  int `json:"price_ceil,omitempty" yaml:"price_ceil"`

	// app can be created by api
	Apps []core.App `opts:"-" json:"apps,omitempty" yaml:"apps"`
}

func NewConfig() *Config {
	return &Config{
		Addr:       ":30911",
		PriceFloor: 20,
	}
}
