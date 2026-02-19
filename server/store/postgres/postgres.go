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

package postgres

import (
	"log"
	"os"
	"strings"
	"time"

	"go.zoe.im/payserver/server/core"
	"go.zoe.im/payserver/server/store"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var _ store.Storage = (*driver)(nil)

type driver struct {
	*gorm.DB
	c *store.Config
}

// New creates a new PostgreSQL storage driver
func New(c *store.Config) (store.Storage, error) {
	dbConfig := &gorm.Config{}

	dbConfig.Logger = logger.New(
		log.New(os.Stdout, "\r\n", log.LstdFlags),
		logger.Config{
			SlowThreshold: time.Second,
			LogLevel:      logger.Silent,
			Colorful:      false,
		},
	)

	d := &driver{c: c}
	var err error

	// Parse DSN from URI
	// postgres://user:pass@localhost:5432/dbname?sslmode=disable
	dsn := c.URI
	dsn = strings.TrimPrefix(dsn, "postgres://")
	dsn = strings.TrimPrefix(dsn, "postgresql://")

	// Convert to GORM-compatible DSN format
	dsn = parseToDSN(dsn)

	d.DB, err = gorm.Open(postgres.Open(dsn), dbConfig)
	if err != nil {
		return nil, err
	}

	if c.Debug {
		d.DB = d.DB.Session(&gorm.Session{
			Logger: d.DB.Logger.LogMode(logger.Info),
		})
	}

	// Configure connection pool
	sqlDB, err := d.DB.DB()
	if err != nil {
		return nil, err
	}
	sqlDB.SetMaxIdleConns(10)
	sqlDB.SetMaxOpenConns(100)
	sqlDB.SetConnMaxLifetime(time.Hour)

	// Setup join tables
	err = d.DB.SetupJoinTable(&core.App{}, "Agents", &core.AppAgentBind{})
	if err != nil {
		return nil, err
	}

	// Auto migrate
	return d, d.DB.AutoMigrate(
		&core.Account{},
		&core.App{},
		&core.Agent{},
		&core.Order{},
		&core.PayRecord{},
		&core.CallbackLog{},
	)
}

// parseToDSN converts URI format to GORM DSN format
// user:pass@localhost:5432/dbname?sslmode=disable
// -> host=localhost port=5432 user=user password=pass dbname=dbname sslmode=disable
func parseToDSN(uri string) string {
	// If already in DSN format, return as-is
	if strings.Contains(uri, "host=") {
		return uri
	}

	// Parse URI format: user:pass@host:port/dbname?params
	var user, pass, host, port, dbname, params string

	// Extract params
	if idx := strings.Index(uri, "?"); idx != -1 {
		params = uri[idx+1:]
		uri = uri[:idx]
	}

	// Extract dbname
	if idx := strings.LastIndex(uri, "/"); idx != -1 {
		dbname = uri[idx+1:]
		uri = uri[:idx]
	}

	// Extract user:pass and host:port
	if idx := strings.LastIndex(uri, "@"); idx != -1 {
		userPass := uri[:idx]
		hostPort := uri[idx+1:]

		// Parse user:pass
		if idx := strings.Index(userPass, ":"); idx != -1 {
			user = userPass[:idx]
			pass = userPass[idx+1:]
		} else {
			user = userPass
		}

		// Parse host:port
		if idx := strings.LastIndex(hostPort, ":"); idx != -1 {
			host = hostPort[:idx]
			port = hostPort[idx+1:]
		} else {
			host = hostPort
			port = "5432"
		}
	} else {
		// No auth info, just host:port
		if idx := strings.LastIndex(uri, ":"); idx != -1 {
			host = uri[:idx]
			port = uri[idx+1:]
		} else {
			host = uri
			port = "5432"
		}
	}

	// Build DSN
	dsn := "host=" + host + " port=" + port
	if user != "" {
		dsn += " user=" + user
	}
	if pass != "" {
		dsn += " password=" + pass
	}
	if dbname != "" {
		dsn += " dbname=" + dbname
	}
	if params != "" {
		// Convert params to DSN format
		for _, param := range strings.Split(params, "&") {
			parts := strings.SplitN(param, "=", 2)
			if len(parts) == 2 {
				dsn += " " + parts[0] + "=" + parts[1]
			}
		}
	}

	return dsn
}

func init() {
	store.Register(New, "postgres", "postgresql")
}

// ==================== AgentStore ====================

func (d *driver) CreateAgent(a *core.Agent) (*core.Agent, error) {
	return a, d.Create(a).Error
}

func (d *driver) UpdateAgent(a *core.Agent) (*core.Agent, error) {
	return a, d.Model(a).Updates(a).Error
}

func (d *driver) GetAgent(id string) (*core.Agent, error) {
	var a core.Agent
	return &a, d.Where("uid = ?", id).First(&a).Error
}

func (d *driver) GetAgentByTicket(ticket string) (*core.Agent, error) {
	var a core.Agent
	return &a, d.Where("ticket = ?", ticket).First(&a).Error
}

func (d *driver) DeleteAgent(uid string) error {
	if uid == "" {
		return store.ErrMissObjectID
	}
	return d.Where("uid = ?", uid).Delete(&core.Agent{}).Error
}

func (d *driver) CountPenddingAgents() (int, error) {
	var count int64
	return int(count), d.Model(&core.Agent{}).
		Where("status = ?", core.AgentStatusPendding).
		Count(&count).Error
}

func (d *driver) ListAgents(offset, limit int, query ...interface{}) ([]*core.Agent, error) {
	var as []*core.Agent
	return as, d.Where(query).Limit(limit).Offset(offset).Find(&as).Error
}

// ==================== AppStore ====================

func (d *driver) CreateApp(app *core.App) (*core.App, error) {
	return app, d.Create(app).Error
}

func (d *driver) GetApp(id string) (*core.App, error) {
	var app core.App
	return &app, d.Where("uid = ?", id).First(&app).Error
}

func (d *driver) GetAppByName(name string) (*core.App, error) {
	var app core.App
	return &app, d.Where("name = ?", name).First(&app).Error
}

func (d *driver) DeleteApp(id string) error {
	return d.Where("uid = ?", id).Delete(&core.App{}).Error
}

func (d *driver) UpdateApp(app *core.App) (*core.App, error) {
	return app, d.Model(app).Updates(app).Error
}

func (d *driver) ListApps(offset, limit int, query ...interface{}) ([]*core.App, error) {
	var apps []*core.App
	return apps, d.Where(query).Offset(offset).Limit(limit).Find(&apps).Error
}

// ==================== OrderStore ====================

func (d *driver) CreateOrder(or *core.Order) (*core.Order, error) {
	return or, d.Create(or).Error
}

func (d *driver) UpdateOrder(or *core.Order) (*core.Order, error) {
	if or.UID == "" {
		return nil, store.ErrMissObjectID
	}
	return or, d.Model(or).Where("uid = ?", or.UID).Updates(or).Error
}

func (d *driver) DeleteOrder(uid string) error {
	if uid == "" {
		return store.ErrMissObjectID
	}
	return d.Where("uid = ?", uid).Delete(&core.Order{}).Error
}

func (d *driver) GetOrder(uid string) (*core.Order, error) {
	var or core.Order
	return &or, d.Where("uid = ?", uid).First(&or).Error
}

func (d *driver) GetOrderByAppAndNumber(appid string, num string) (*core.Order, error) {
	var or core.Order
	return &or, d.Where("app_id = ? AND o_number = ?", appid, num).First(&or).Error
}

func (d *driver) GetOrdersByApp(appid string, statuss ...core.OrderStatus) ([]*core.Order, error) {
	var orders []*core.Order
	query := d.Where("app_id = ?", appid)
	if len(statuss) > 0 {
		query = query.Where("status IN ?", statuss)
	}
	return orders, query.Find(&orders).Error
}

func (d *driver) ListOrders(offset, limit int, query ...interface{}) ([]*core.Order, error) {
	var orders []*core.Order
	return orders, d.Where(query).Offset(offset).Limit(limit).Order("created_at DESC").Find(&orders).Error
}

// ==================== RecordStore ====================

func (d *driver) CreateRecord(rd *core.PayRecord) (*core.PayRecord, error) {
	return rd, d.Create(rd).Error
}

func (d *driver) GetRecord(uid string) (*core.PayRecord, error) {
	var rd core.PayRecord
	return &rd, d.Where("uid = ?", uid).First(&rd).Error
}

func (d *driver) ListRecords(offset, limit int, query ...interface{}) ([]*core.PayRecord, error) {
	var rs []*core.PayRecord
	return rs, d.Where(query).Offset(offset).Limit(limit).Find(&rs).Error
}

func (d *driver) UpdateRecord(rd *core.PayRecord) (*core.PayRecord, error) {
	if rd.UID == "" {
		return nil, store.ErrMissObjectID
	}
	return rd, d.Model(rd).Where("uid = ?", rd.UID).Updates(rd).Error
}

func (d *driver) DeleteRecord(uid string) error {
	if uid == "" {
		return store.ErrMissObjectID
	}
	return d.Where("uid = ?", uid).Delete(&core.PayRecord{}).Error
}

// ==================== CallbackStore ====================

func (d *driver) CreateCallback(cb *core.CallbackLog) (*core.CallbackLog, error) {
	return cb, d.Create(cb).Error
}

func (d *driver) UpdateCallback(cb *core.CallbackLog) (*core.CallbackLog, error) {
	if cb.UID == "" {
		return nil, store.ErrMissObjectID
	}
	return cb, d.Model(cb).Where("uid = ?", cb.UID).Updates(cb).Error
}

func (d *driver) GetCallback(uid string) (*core.CallbackLog, error) {
	var cb core.CallbackLog
	return &cb, d.Where("uid = ?", uid).First(&cb).Error
}

func (d *driver) GetCallbackByOrder(orderUID string) (*core.CallbackLog, error) {
	var cb core.CallbackLog
	return &cb, d.Where("order_uid = ?", orderUID).Order("created_at DESC").First(&cb).Error
}

func (d *driver) ListPendingCallbacks(limit int) ([]*core.CallbackLog, error) {
	var cbs []*core.CallbackLog
	now := time.Now()
	return cbs, d.Where("status = ? AND next_attempt <= ?", core.CallbackStatusPending, now).
		Order("next_attempt ASC").
		Limit(limit).
		Find(&cbs).Error
}

func (d *driver) ListCallbacksByOrder(orderUID string) ([]*core.CallbackLog, error) {
	var cbs []*core.CallbackLog
	return cbs, d.Where("order_uid = ?", orderUID).Order("created_at DESC").Find(&cbs).Error
}
