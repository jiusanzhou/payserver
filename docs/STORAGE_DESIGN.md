# 存储层插件架构设计

> 多数据库后端支持：Supabase (优先)、PostgreSQL、MySQL

## 目录

- [设计目标](#设计目标)
- [现有架构分析](#现有架构分析)
- [插件架构设计](#插件架构设计)
- [Supabase 适配器](#supabase-适配器)
- [PostgreSQL 适配器](#postgresql-适配器)
- [MySQL 适配器](#mysql-适配器)
- [配置管理](#配置管理)
- [迁移方案](#迁移方案)

---

## 设计目标

1. **插件化**: 通过 URI scheme 自动选择存储后端
2. **统一接口**: 所有存储后端实现相同的 `Storage` 接口
3. **零侵入**: 业务代码不感知具体数据库类型
4. **Supabase 优先**: 优先支持 Supabase，利用其 Auth/Realtime 能力
5. **易扩展**: 便于添加新的数据库支持

---

## 现有架构分析

当前项目已经有良好的存储抽象层设计:

```go
// store/store.go
type Storage interface {
    AgentStore
    OrderStore
    RecordStore
    AppStore
}

type AgentStore interface {
    CreateAgent(*core.Agent) (*core.Agent, error)
    UpdateAgent(*core.Agent) (*core.Agent, error)
    GetAgent(id string) (*core.Agent, error)
    // ...
}

// 注册机制
type StorageCreator func(*Config) (Storage, error)
var registry = make(map[string]StorageCreator)

func Register(r StorageCreator, schemas ...string) error
func New(opts ...Option) (Storage, error)
```

当前实现:
- `msql/` - 支持 MySQL 和 SQLite (通过 GORM)

**优点**:
- 接口设计清晰
- 注册机制灵活
- 使用 GORM 便于多数据库支持

**需要增强**:
- 添加 PostgreSQL 驱动注册
- 添加 Supabase 特定支持（Row Level Security、Realtime）
- 统一配置管理

---

## 插件架构设计

### 整体架构

```
                    +------------------------+
                    |     Application        |
                    |   (server, service)    |
                    +-----------+------------+
                                |
                    +-----------v------------+
                    |   Storage Interface    |
                    | (AgentStore, OrderStore|
                    |  RecordStore, AppStore)|
                    +-----------+------------+
                                |
              +-----------------+-----------------+
              |                 |                 |
    +---------v---------+  +----v----+  +---------v---------+
    |  Supabase Adapter |  |PostgreSQL|  |   MySQL Adapter   |
    |                   |  | Adapter  |  |                   |
    |  - GORM + pgx     |  | - GORM   |  |  - GORM (已有)    |
    |  - RLS Support    |  | - pgx    |  |                   |
    |  - Realtime Hook  |  |          |  |                   |
    +-------------------+  +---------+  +-------------------+
```

### 目录结构

```
server/store/
|-- store.go            # 接口定义 (已有)
|-- config.go           # 配置结构 (已有)
|-- msql/               # MySQL/SQLite (已有，重命名为 mysql/)
|   |-- msql.go
|   |-- store_agent.go
|   |-- store_app.go
|   |-- store_order.go
|   +-- store_record.go
|-- postgres/           # PostgreSQL (新增)
|   |-- postgres.go
|   |-- store_agent.go
|   |-- store_app.go
|   |-- store_order.go
|   +-- store_record.go
+-- supabase/           # Supabase (新增)
    |-- supabase.go
    |-- store_agent.go
    |-- store_app.go
    |-- store_order.go
    |-- store_record.go
    +-- realtime.go     # Realtime 支持
```

---

## Supabase 适配器

### 特点

Supabase 基于 PostgreSQL，但提供额外能力:

1. **Row Level Security (RLS)**: 数据库级别的权限控制
2. **Realtime**: 实时数据变更推送
3. **Auth**: 内置认证系统
4. **REST API**: 自动生成 REST API (PostgREST)

### 连接方式选择

| 方式 | 适用场景 | 延迟 | 连接池 |
|------|----------|------|--------|
| Direct Connection | 长期运行的服务器 | 最低 | 需要管理 |
| Supabase Pooler | Serverless/Edge | 较低 | 自动管理 |
| REST API | 简单查询/JS客户端 | 较高 | 无需管理 |

**推荐**: Go Backend 使用 Direct Connection / Pooler

### 实现代码

```go
// store/supabase/supabase.go
package supabase

import (
    "fmt"
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
    
    // Supabase 特定配置
    projectURL string
    anonKey    string
    serviceKey string
}

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

    // 解析 Supabase URI
    // 格式: supabase://user:pass@project-ref.supabase.co:5432/postgres
    dsn, err := parseSupabaseURI(c.URI)
    if err != nil {
        return nil, err
    }

    d.DB, err = gorm.Open(postgres.Open(dsn), dbConfig)
    if err != nil {
        return nil, err
    }

    if c.Debug {
        d.DB = d.DB.Session(&gorm.Session{
            Logger: d.DB.Logger.LogMode(logger.Info),
        })
    }

    // 配置连接池
    sqlDB, _ := d.DB.DB()
    sqlDB.SetMaxIdleConns(10)
    sqlDB.SetMaxOpenConns(100)
    sqlDB.SetConnMaxLifetime(time.Hour)

    // 自动迁移
    return d, d.DB.AutoMigrate(
        &core.Account{},
        &core.App{},
        &core.Agent{},
        &core.Order{},
        &core.PayRecord{},
    )
}

func parseSupabaseURI(uri string) (string, error) {
    // supabase://user:pass@db.xxx.supabase.co:5432/postgres
    // -> postgresql://user:pass@db.xxx.supabase.co:5432/postgres
    if strings.HasPrefix(uri, "supabase://") {
        return "postgresql://" + strings.TrimPrefix(uri, "supabase://"), nil
    }
    return uri, nil
}

func init() {
    store.Register(New, "supabase")
}
```

### RLS 支持

```go
// store/supabase/rls.go
package supabase

import (
    "context"
    "gorm.io/gorm"
)

// WithUserContext 设置 RLS 用户上下文
func (d *driver) WithUserContext(ctx context.Context, userID string) *gorm.DB {
    return d.DB.WithContext(ctx).Exec(
        "SET LOCAL request.jwt.claims = ?",
        fmt.Sprintf(`{"sub": "%s"}`, userID),
    )
}

// 示例：启用 RLS 的查询
func (d *driver) GetAppsByUser(userID string) ([]*core.App, error) {
    var apps []*core.App
    
    // 通过 RLS，只返回该用户有权限的 apps
    err := d.WithUserContext(context.Background(), userID).
        Find(&apps).Error
    
    return apps, err
}
```

### Realtime 支持

```go
// store/supabase/realtime.go
package supabase

import (
    "encoding/json"
    "net/http"
    "github.com/gorilla/websocket"
)

// RealtimeClient Supabase Realtime 客户端
type RealtimeClient struct {
    conn       *websocket.Conn
    projectURL string
    apiKey     string
}

// Subscribe 订阅表变更
func (r *RealtimeClient) Subscribe(table string, callback func(ChangeEvent)) error {
    // 连接 Supabase Realtime
    url := fmt.Sprintf("wss://%s/realtime/v1/websocket?apikey=%s",
        r.projectURL, r.apiKey)
    
    conn, _, err := websocket.DefaultDialer.Dial(url, nil)
    if err != nil {
        return err
    }
    r.conn = conn

    // 订阅消息
    subscription := map[string]interface{}{
        "event": "phx_join",
        "topic": fmt.Sprintf("realtime:public:%s", table),
        "payload": map[string]interface{}{},
        "ref": "1",
    }
    
    r.conn.WriteJSON(subscription)
    
    // 监听变更
    go func() {
        for {
            _, message, err := r.conn.ReadMessage()
            if err != nil {
                return
            }
            
            var event ChangeEvent
            json.Unmarshal(message, &event)
            callback(event)
        }
    }()
    
    return nil
}

type ChangeEvent struct {
    Table  string                 `json:"table"`
    Type   string                 `json:"type"` // INSERT, UPDATE, DELETE
    Record map[string]interface{} `json:"record"`
    Old    map[string]interface{} `json:"old_record"`
}
```

---

## PostgreSQL 适配器

PostgreSQL 适配器使用标准 GORM postgres driver:

```go
// store/postgres/postgres.go
package postgres

import (
    "log"
    "os"
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

    // postgres://user:pass@localhost:5432/dbname?sslmode=disable
    dsn := strings.TrimPrefix(c.URI, "postgres://")
    dsn = strings.TrimPrefix(dsn, "postgresql://")

    d.DB, err = gorm.Open(postgres.Open(dsn), dbConfig)
    if err != nil {
        return nil, err
    }

    if c.Debug {
        d.DB = d.DB.Session(&gorm.Session{
            Logger: d.DB.Logger.LogMode(logger.Info),
        })
    }

    // 配置连接池
    sqlDB, _ := d.DB.DB()
    sqlDB.SetMaxIdleConns(10)
    sqlDB.SetMaxOpenConns(100)
    sqlDB.SetConnMaxLifetime(time.Hour)

    return d, d.DB.AutoMigrate(
        &core.Account{},
        &core.App{},
        &core.Agent{},
        &core.Order{},
        &core.PayRecord{},
    )
}

func init() {
    store.Register(New, "postgres", "postgresql")
}
```

### Store 实现复用

由于使用 GORM，大部分 Store 实现可以复用:

```go
// store/postgres/store_agent.go
package postgres

import (
    "go.zoe.im/payserver/server/core"
)

func (d *driver) CreateAgent(agent *core.Agent) (*core.Agent, error) {
    err := d.DB.Create(agent).Error
    return agent, err
}

func (d *driver) UpdateAgent(agent *core.Agent) (*core.Agent, error) {
    err := d.DB.Save(agent).Error
    return agent, err
}

func (d *driver) GetAgent(id string) (*core.Agent, error) {
    var agent core.Agent
    err := d.DB.Where("uid = ?", id).First(&agent).Error
    return &agent, err
}

// ... 其他方法与 msql 实现相同
```

---

## MySQL 适配器

当前 `msql/` 已经支持 MySQL，只需确保注册正确:

```go
// store/msql/msql.go (修改)
func init() {
    store.Register(New, "mysql", "sqlite3", "sqlite")
    
    RegisterDriver(sqlite.Open, "sqlite", "sqlite3")
    RegisterDriver(mysql.Open, "mysql")
}
```

---

## 配置管理

### 配置结构增强

```go
// store/config.go
package store

type Config struct {
    URI   string // 数据库连接 URI
    Debug bool   // 调试模式
    
    // 连接池配置
    MaxIdleConns    int           // 最大空闲连接
    MaxOpenConns    int           // 最大打开连接
    ConnMaxLifetime time.Duration // 连接最大生命周期
    
    // Supabase 特定配置
    SupabaseProjectURL string // Supabase 项目 URL
    SupabaseAnonKey    string // Supabase Anonymous Key
    SupabaseServiceKey string // Supabase Service Role Key
}

// 默认配置
func NewConfig(opts ...Option) *Config {
    c := &Config{
        MaxIdleConns:    10,
        MaxOpenConns:    100,
        ConnMaxLifetime: time.Hour,
    }
    for _, opt := range opts {
        opt(c)
    }
    return c
}
```

### 配置示例

```toml
# config.toml

# 方式 1: SQLite (开发/测试)
db = "sqlite3://data/payserver.db"

# 方式 2: MySQL
# db = "mysql://user:pass@tcp(localhost:3306)/payserver?charset=utf8mb4&parseTime=True&loc=Local"

# 方式 3: PostgreSQL
# db = "postgres://user:pass@localhost:5432/payserver?sslmode=disable"

# 方式 4: Supabase (推荐生产环境)
# db = "supabase://postgres.xxx:pass@db.xxx.supabase.co:5432/postgres"

# 如果使用 Supabase，可选配置
# supabase_project_url = "https://xxx.supabase.co"
# supabase_anon_key = "eyJxxx"
# supabase_service_key = "eyJxxx"
```

### 环境变量支持

```go
// config/config.go 修改
func NewConfig() *Config {
    c := &Config{
        Addr:       getEnv("PAYSERVER_ADDR", ":30911"),
        DB:         getEnv("PAYSERVER_DB", "sqlite3://default.sqlite3"),
        Debug:      getEnv("PAYSERVER_DEBUG", "false") == "true",
        
        // Supabase
        SupabaseProjectURL: os.Getenv("SUPABASE_URL"),
        SupabaseAnonKey:    os.Getenv("SUPABASE_ANON_KEY"),
        SupabaseServiceKey: os.Getenv("SUPABASE_SERVICE_ROLE_KEY"),
    }
    return c
}

func getEnv(key, defaultVal string) string {
    if val := os.Getenv(key); val != "" {
        return val
    }
    return defaultVal
}
```

---

## 迁移方案

### 数据迁移脚本

```bash
#!/bin/bash
# scripts/migrate-to-supabase.sh

# 1. 从 SQLite/MySQL 导出数据
pg_dump --data-only --inserts source_db > data.sql

# 2. 修改 SQL 适配 PostgreSQL 语法 (如需要)
sed -i 's/AUTO_INCREMENT/SERIAL/g' data.sql

# 3. 导入到 Supabase
psql "postgresql://postgres:pass@db.xxx.supabase.co:5432/postgres" < data.sql
```

### Go 迁移工具

```go
// cmd/migrate/main.go
package main

import (
    "flag"
    "log"
    
    "go.zoe.im/payserver/server/store"
    _ "go.zoe.im/payserver/server/store/msql"
    _ "go.zoe.im/payserver/server/store/postgres"
    _ "go.zoe.im/payserver/server/store/supabase"
)

func main() {
    from := flag.String("from", "", "Source database URI")
    to := flag.String("to", "", "Target database URI")
    flag.Parse()
    
    if *from == "" || *to == "" {
        log.Fatal("Usage: migrate -from <source_uri> -to <target_uri>")
    }
    
    sourceStore, err := store.New(store.OptionURI(*from))
    if err != nil {
        log.Fatalf("Failed to connect source: %v", err)
    }
    
    targetStore, err := store.New(store.OptionURI(*to))
    if err != nil {
        log.Fatalf("Failed to connect target: %v", err)
    }
    
    // 迁移 Agents
    agents, _ := sourceStore.ListAgents(0, 10000)
    for _, agent := range agents {
        targetStore.CreateAgent(agent)
    }
    
    // 迁移 Apps
    apps, _ := sourceStore.ListApps(0, 10000)
    for _, app := range apps {
        targetStore.CreateApp(app)
    }
    
    // 迁移 Orders 和 Records...
    
    log.Println("Migration completed!")
}
```

---

## 使用示例

### 启动时选择数据库

```bash
# SQLite (开发)
./payserver -db "sqlite3://data/dev.db"

# MySQL
./payserver -db "mysql://user:pass@tcp(localhost:3306)/payserver"

# PostgreSQL
./payserver -db "postgres://user:pass@localhost:5432/payserver"

# Supabase
./payserver -db "supabase://postgres:pass@db.xxx.supabase.co:5432/postgres"
```

### 代码中使用

```go
// 业务代码完全不感知数据库类型
func (s *Service) Run() error {
    // 根据配置自动选择存储后端
    store, err := store.New(
        store.OptionURI(s.Config.DB),
        store.OptionDebug(s.Config.Debug),
    )
    if err != nil {
        return err
    }
    
    // 使用统一接口
    agents, err := store.ListAgents(0, 10)
    // ...
}
```

---

## 测试策略

### 多数据库测试

```go
// store/store_test.go
package store_test

import (
    "testing"
    
    "go.zoe.im/payserver/server/store"
    _ "go.zoe.im/payserver/server/store/msql"
    _ "go.zoe.im/payserver/server/store/postgres"
    _ "go.zoe.im/payserver/server/store/supabase"
)

var testDatabases = []string{
    "sqlite3://:memory:",
    "mysql://test:test@tcp(localhost:3306)/test",
    "postgres://test:test@localhost:5432/test?sslmode=disable",
}

func TestStorageImplementations(t *testing.T) {
    for _, uri := range testDatabases {
        t.Run(uri, func(t *testing.T) {
            s, err := store.New(store.OptionURI(uri))
            if err != nil {
                t.Skipf("Database not available: %v", err)
                return
            }
            
            // 测试 CRUD 操作
            testAgentCRUD(t, s)
            testAppCRUD(t, s)
            testOrderCRUD(t, s)
        })
    }
}
```

---

## 下一步

1. [Agent 升级设计](./AGENT_DESIGN.md) - Flutter 端升级方案
2. [API 规范](./API.md) - RESTful API 接口文档
