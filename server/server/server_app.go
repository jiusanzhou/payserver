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
	"errors"
	"strings"

	"github.com/google/uuid"
	"go.zoe.im/payserver/server/core"
)

func (s *Server) EnsureApp(app *core.App) error {
	if !strings.HasPrefix(app.CallbackURL, "http") {
		return errors.New("callback shoube be a url")
	}

	if app.ExpireIn == 0 {
		app.ExpireIn = s.c.ExpireIn
	}

	if app.PriceCeil <= 0 {
		app.PriceCeil = s.c.PriceCeil
	}

	if app.PriceFloor <= 0 {
		app.PriceFloor = s.c.PriceFloor
	}

	if app.MaxPenddingOrder <= 0 {
		app.MaxPenddingOrder = s.c.MaxPenddingOrder
	}

	return nil
}

func (s *Server) CreateApp(app *core.App) (*core.App, error) {
	if err := s.EnsureApp(app); err != nil {
		return nil, err
	}

	// secret ...
	app.Secret = uuid.New().String()

	// TODO: aes key
	// TODO: get and set create user

	return s.store.CreateApp(app)
}

func (s *Server) GetApp(id string) (*core.App, error) {
	return s.store.GetApp(id)
}

func (s *Server) DeleteApp(id string) error {
	return s.store.DeleteApp(id)
}

func (s *Server) UpdateApp(id string, app *core.App) (*core.App, error) {
	if err := s.EnsureApp(app); err != nil {
		return nil, err
	}

	app.UID = id
	return s.store.UpdateApp(app)
}

func (s *Server) ListApps(offset, limit int) ([]*core.App, error) {
	return s.store.ListApps(offset, limit)
}

func (s *Server) ListAppsByAgent(id string, offset, limit int) ([]*core.App, error) {
	return s.store.ListApps(offset, limit, "agent_uid = ?", id)
}
