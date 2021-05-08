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

package store

// Config ...
type Config struct {
	URI   string
	Debug bool
}

func NewConfig(opts ...Option) *Config {
	c := &Config{}
	for _, i := range opts {
		i(c)
	}
	return c
}

type Option func(c *Config)

func OptionURI(u string) Option {
	return func(c *Config) {
		c.URI = u
	}
}

func OptionDebug(v bool) Option {
	return func(c *Config) {
		c.Debug = v
	}
}
