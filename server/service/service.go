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
	"bytes"
	"encoding/json"
	"fmt"
	"log"

	"go.zoe.im/payserver/server/apis"
	"go.zoe.im/payserver/server/config"
	"go.zoe.im/payserver/server/server"
	"go.zoe.im/payserver/server/store"

	"go.zoe.im/x"
)

type Service struct {
	*config.Config

	store  store.Storage
	server *server.Server
	webapi *apis.WebAPI
}

func (s *Service) Run() error {
	var err error

	// check config
	if err = s.Config.Validate(); err != nil {
		return err
	}

	if s.Config.Debug {
		log.Println("[DEBUG] open debug mode")
	}

	// init or start other things
	if s.store, err = store.New(store.OptionURI(s.DB), store.OptionDebug(s.Debug)); err != nil {
		return err
	}

	// TODO: inject?
	s.server = server.New(s.Config, s.store)
	s.webapi = apis.NewWebAPI(s.server)

	// boostrap
	if err = s.Boostrap(); err != nil {
		return err
	}

	// grace start
	err = x.GraceRun(func() error {
		return s.startHTTP()
	})

	fmt.Println("\nExit service ...")

	// TODO: clean

	return err
}

func (s *Service) Boostrap() error {
	// bootstrap the server
	for _, a := range s.Config.Apps {
		// check the name
		if a.Name == "" {
			log.Println("[WARN] app must have a name")
			continue
		}

		// create or update app
		if b, err := s.store.GetAppByName(a.Name); err == nil {
			// update the app
			log.Println("[INFO] update the app", b.UID)
			c, err := s.server.UpdateApp(b.UID, &a)
			if err != nil {
				log.Println("[ERROR] update error", err)
			} else {
				var buf bytes.Buffer
				json.NewEncoder(&buf).Encode(c)
				log.Println("[INFO] update success =>", buf.String())
			}
		} else {
			// can't found one, just create
			// create the app
			log.Println("[INFO] create the app")
			c, err := s.server.CreateApp(&a)
			if err != nil {
				log.Println("[ERROR] create error", err)
			} else {
				var buf bytes.Buffer
				json.NewEncoder(&buf).Encode(c)
				log.Println("[INFO] create success =>", buf.String())
			}
		}
	}

	return nil
}

func New() *Service {
	s := &Service{
		Config: config.NewConfig(),
	}

	return s
}
