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

package server

import (
	"go.zoe.im/payserver/server/config"
	"go.zoe.im/payserver/server/store"
)

type Server struct {
	store store.Storage
	c     *config.Config
}

func (s Server) Name() string {
	// TODO:
	return s.c.Name
}

func New(c *config.Config, store store.Storage) *Server {
	s := &Server{
		store: store,
		c:     c,
	}

	return s
}
