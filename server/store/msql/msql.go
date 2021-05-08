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

package msql

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/store"

	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"gorm.io/driver/mysql"
	"gorm.io/driver/sqlite"
)

var _ store.Storage = (*driver)(nil)

// DBConn mysql connection
var DBConn *gorm.DB

type driver struct {
	db *gorm.DB // The main db object
	c  *store.Config
}

// New 创建数据库
func New(c *store.Config) (store.Storage, error) {
	dbConfig := &gorm.Config{}

	// turn on debug for msql
	if c.Debug {
		dbConfig.Logger = logger.New(
			log.New(os.Stdout, "\r\n", log.LstdFlags), // io writer
			logger.Config{
				SlowThreshold: time.Second,   // 慢 SQL 阈值
				LogLevel:      logger.Silent, // Log level
				Colorful:      false,         // 禁用彩色打印
			},
		)
	}

	var err error
	d := &driver{}

	if c.URI == "" {
		c.URI = "sqlite3://default.sqlite3"
	}

	parts := strings.Split(c.URI, "://")
	if len(parts) != 2 {
		return nil, fmt.Errorf("schema not supported: %s", c.URI)
	}

	dial, err := OpenDialector(parts[0], parts[1])
	if err != nil {
		return nil, err
	}

	d.db, err = gorm.Open(dial, dbConfig)
	if err != nil {
		return nil, err
	}

	// global store the db
	DBConn = d.db

	// init/create the table if we need
	return d, d.db.AutoMigrate(
		&core.Order{},
		&core.Record{},
	)
}

func init() {
	store.Register(New, "mysql", "sqlite3", "postgres", "")

	RegisterDriver(sqlite.Open, "sqlite", "sqlite3")
	RegisterDriver(mysql.Open, "mysql")
}

// ===================

var driverRegistry = map[string]func(dsn string) gorm.Dialector{}

// RegisterDriver ...
func RegisterDriver(fn func(dsn string) gorm.Dialector, schemas ...string) error {

	for _, s := range schemas {
		driverRegistry[s] = fn
	}

	return nil
}

// OpenDialector gorm dialector
func OpenDialector(typ string, dsn string) (gorm.Dialector, error) {
	fn, ok := driverRegistry[typ]
	if !ok {
		return nil, fmt.Errorf("no gorm dialector: %s", typ)
	}
	return fn(dsn), nil
}
