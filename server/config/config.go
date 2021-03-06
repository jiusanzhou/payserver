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

import (
	"errors"
	"net/url"

	"go.zoe.im/payserver/server/core"
)

type Config struct {
	Addr            string `json:"addr,omitempty" yaml:"addr"`
	DB              string `json:"db,omitempty" yaml:"db"`
	Debug           bool   `json:"debug,omitempty" yaml:"debug"`
	HTTPAllowOrigin string `json:"http_allow_origin,omitempty" yaml:"http_allow_origin"`

	// only for client/agent to register
	Name    string `json:"name,omitempty" yaml:"name"`
	Host    string `json:"host,omitempty" yaml:"host"`
	Version string `json:"version,omitempty" yaml:"version"`

	// default price floor and ceil
	PriceFloor int `json:"price_floor,omitempty" yaml:"price_floor"` // -
	PriceCeil  int `json:"price_ceil,omitempty" yaml:"price_ceil"`   // +

	// default configuraton for app
	// order expire duration in second
	ExpireIn         int `json:"expire_in,omitempty" yaml:"expire_in"`
	MaxPenddingOrder int `json:"max_pendding_order,omitempty" yaml:"max_pendding_order"`

	// max pendding for register, creatting limited
	MaxPenddingAgent int `json:"max_pendding_agent,omitempty" yaml:"max_pendding_agent"`

	// app can be created by api, TODO: should bind for user
	Apps []core.App `opts:"-" json:"apps,omitempty" yaml:"apps"`

	// TODO: limit requests
}

// Validate TODO: auto generate from tag
// TODO: auto add default value from tag or struct
func (c *Config) Validate() error {
	if c.Name == "" {
		return errors.New("name can't be empty")
	}

	if _, err := url.Parse(c.Host); err != nil {
		return errors.New("host is invalidated")
	}

	if c.Version == "" {
		// TODO: c.Version must lease than x.Version
		c.Version = "v1"
	}

	return nil
}

func NewConfig() *Config {
	return &Config{
		Addr:       ":30911",
		PriceFloor: 20, // -0.01 - -0.2 (amost 20)

		Name:    "?????????",
		Version: "v1",
	}
}
