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
	"reflect"
	"sync"
	"testing"

	"go.zoe.im/payserver/server/config"
	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/store"
)

func TestServer_CreateOrder(t *testing.T) {
	type fields struct {
		store     store.Storage
		uniqueIDs map[string]bool
		RWMutex   sync.RWMutex
		c         *config.Config
	}
	type args struct {
		appid    string
		method   string
		preorder *core.PreOrder
	}
	tests := []struct {
		name    string
		fields  fields
		args    args
		want    *core.Order
		wantErr bool
	}{
		// TODO: Add test cases.
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			s := &Server{
				store:     tt.fields.store,
				uniqueIDs: tt.fields.uniqueIDs,
				RWMutex:   tt.fields.RWMutex,
				c:         tt.fields.c,
			}
			got, err := s.CreateOrder(tt.args.appid, tt.args.method, tt.args.preorder)
			if (err != nil) != tt.wantErr {
				t.Errorf("Server.CreateOrder() error = %v, wantErr %v", err, tt.wantErr)
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("Server.CreateOrder() = %v, want %v", got, tt.want)
			}
		})
	}
}
