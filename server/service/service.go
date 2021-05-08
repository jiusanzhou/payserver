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

package service

import (
	"fmt"

	"go.zoe.im/payserver/server/config"
	"go.zoe.im/payserver/server/store"

	"go.zoe.im/x"
)

type Server struct {
	*config.Config

	store store.Storage
}

func (s *Server) Run() error {
	var err error

	// init or start other things
	s.store, err = store.New(store.OptionURI(s.DB), store.OptionDebug(s.Debug))
	if err != nil {
		return err
	}

	err = x.GraceRun(func() error {
		return s.startHTTP()
	})

	fmt.Println("\nExit service ...")

	// TODO: clean

	return err
}

func New() *Server {
	s := &Server{
		Config: config.NewConfig(),
	}

	return s
}
