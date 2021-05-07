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

import (
	"errors"
	"log"
	"strings"

	"go.zoe.im/payserver/server/core"
)

// Storage for storage
type Storage interface {
	OrderStore
	RecordStore
}

type OrderStore interface {
	CreateOrder(*core.Order) (*core.Order, error)
	UpdateOrder(*core.Record) (*core.Record, error)
	DeleteOrder(id string) error
	GetOrder(id string) (*core.Order, error)
	GetOrderByOID(oid string) (*core.Order, error)
}

type RecordStore interface {
	CreateRecord(*core.Record) (*core.Record, error)
	UpdateRecord(*core.Record) (*core.Record, error)
	DeleteRecord(id string) error
}

// ===========================================================

// StorageCreator create a storage
type StorageCreator func(c string) (Storage, error)

var (
	// ErrNoImplement db storage implement
	ErrNoImplement = errors.New("no db storage implement")

	// ErrUnsupportedSchema for error schema config
	ErrUnsupportedSchema = errors.New("unsupported shcema")

	// ErrSchemaExits schema alrealy exits
	ErrSchemaExits = errors.New("schema alrealy exits")

	// SchemaSpliter schema spliter
	SchemaSpliter = "://"

	// registry for storage factory
	registry = make(map[string]StorageCreator)
)

// New create storage from string
// TODO: 一个 string 字段来做 configuration 行不行?
func New(c string) (Storage, error) {

	// parse schema
	schema := strings.Split(c, SchemaSpliter)[0]

	r, ok := registry[schema]
	if !ok {
		log.Printf("cannot found store creator: [%s]", schema)
		return nil, ErrNoImplement
	}

	return r(c)
}

// Register register a creator
func Register(r StorageCreator, schemas ...string) error {

	for _, k := range schemas {
		if _, ok := registry[k]; ok {
			return ErrSchemaExits
		}
		registry[k] = r
	}

	return nil
}
