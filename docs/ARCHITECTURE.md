# PayServer 架构设计文档

> 版本: v2.0 | 更新时间: 2026-02

## 目录

- [系统概述](#系统概述)
- [架构全景图](#架构全景图)
- [核心组件](#核心组件)
- [技术栈](#技术栈)
- [数据流](#数据流)
- [部署架构](#部署架构)

---

## 系统概述

PayServer 是一个个人收款解决方案，通过移动端 Agent 监听支付通知，实时同步到后端服务器，为商户提供简单可靠的收款能力。

### 核心特性

- **实时通知**: 设备收到付款时立即通知后端服务
- **多平台支持**: 支持 Android 和 iOS (部分功能)
- **自动和手动模式**: 支持手动模式，不错过任何一笔收款
- **简单的 API**: 轻松地集成到你的服务中
- **SaaS 和独立部署**: 提供 SaaS 服务，亦可独立部署
- **多数据库支持**: 通过插件化架构支持 Supabase、PostgreSQL、MySQL

---

## 架构全景图

```
+-----------------------------------------------------------------------------+
|                              PayServer System                                |
+-----------------------------------------------------------------------------+
|                                                                              |
|  +------------------+    +--------------------------------------------------+|
|  |   Mobile Agent   |    |              Backend Services                    ||
|  |    (Flutter)     |    |                                                  ||
|  |                  |    |  +---------------------------------------------+ ||
|  |  +------------+  |    |  |        Admin Dashboard (Next.js)           | ||
|  |  |Notification|  |    |  |                                            | ||
|  |  | Listener   |  |    |  |  +---------+ +---------+ +---------+      | ||
|  |  +-----+------+  |    |  |  |Dashboard| | Orders  | | Agents  | ...  | ||
|  |        |         |    |  |  +---------+ +---------+ +---------+      | ||
|  |  +-----v------+  |    |  |                    |                       | ||
|  |  |  Parser    |  |    |  |           +--------v--------+              | ||
|  |  |(WeChat/Ali)|  |    |  |           |   Next.js API   |              | ||
|  |  +-----+------+  |    |  |           |   Routes        |              | ||
|  |        |         |    |  |           +--------+--------+              | ||
|  |  +-----v------+  |    |  +--------------------|-----------------------+ ||
|  |  |Local Store |  |    |                       |                         ||
|  |  | (SQLite)   |  |    |              +--------v---------+               ||
|  |  +-----+------+  |    |              |  Go Backend API  |               ||
|  |        |         |    |              |   (gorilla/mux)  |               ||
|  +--------+---------+    |              +--------+---------+               ||
|           |              |                       |                         ||
|           |  HTTP/WS     |              +--------v---------+               ||
|           +--------------+------------->|   Storage Layer  |               ||
|                          |              |   (Plugin-based) |               ||
|                          |              +--------+---------+               ||
|                          |                       |                         ||
|                          |    +------------------+------------------+      ||
|                          |    |                  |                  |      ||
|                          |    v                  v                  v      ||
|                          | +--------+       +----------+      +---------+  ||
|                          | |Supabase|       |PostgreSQL|      |  MySQL  |  ||
|                          | |(优先)  |       |          |      |         |  ||
|                          | +--------+       +----------+      +---------+  ||
|                          |                                                 ||
|                          +-------------------------------------------------+|
|                                                                              |
|  +--------------------------------------------------------------------------+|
|  |                        External Integrations                              ||
|  |                                                                           ||
|  |  +------------+  +-------------+  +----------------+                     ||
|  |  | Merchant   |  |  Webhook    |  |  Third-party   |                     ||
|  |  | Apps       |  |  Callbacks  |  |  Services      |                     ||
|  |  +------------+  +-------------+  +----------------+                     ||
|  +--------------------------------------------------------------------------+|
+-----------------------------------------------------------------------------+
```

---

## 核心组件

### 1. Mobile Agent (Flutter)

移动端数据采集客户端，负责监听支付通知并上报。

| 模块 | 职责 |
|-----|------|
| Notification Listener | 监听系统通知 (微信支付/支付宝) |
| Transaction Parser | 解析通知内容提取金额等信息 |
| Local Database | SQLite 本地存储，支持离线 |
| Server Connector | 多服务器配置，通知上报 |
| Background Service | 后台持续运行保持监听 |

### 2. Admin Dashboard (Next.js)

管理后台前端，提供可视化管理界面。

| 功能模块 | 说明 |
|---------|------|
| Dashboard | 数据概览、实时统计 |
| Orders | 订单管理、状态追踪 |
| Agents | 设备管理、状态监控 |
| Apps | 应用管理、密钥配置 |
| Records | 收款记录查询 |
| Analytics | 数据分析、报表 |
| Settings | 系统配置 |

### 3. Next.js API Routes

Next.js 内置的 API 层，提供 BFF (Backend For Frontend) 能力。

- 为 Admin Dashboard 提供定制化 API
- 聚合 Go Backend 接口
- 处理认证授权
- Server-Side Rendering 数据预取

### 4. Go Backend

核心业务逻辑服务，提供 RESTful API。

| 层级 | 模块 | 职责 |
|-----|------|------|
| API | `apis/` | HTTP 路由、请求处理 |
| Server | `server/` | 业务逻辑、调度 |
| Core | `core/` | 领域模型、实体定义 |
| Store | `store/` | 存储抽象层 |
| Service | `service/` | 服务编排、启动 |
| Config | `config/` | 配置管理 |

### 5. Storage Layer (Plugin-based)

插件化存储层，支持多种数据库后端。

```
+----------------------------------------+
|           Storage Interface            |
|    (AgentStore, OrderStore, etc.)      |
+----------------------------------------+
|              Adapter Layer             |
+----------+----------+------------------+
| Supabase | Postgres |      MySQL       |
| Adapter  | Adapter  |     Adapter      |
+----------+----------+------------------+
```

---

## 技术栈

### 后端

| 技术 | 用途 | 版本 |
|-----|------|------|
| Go | 核心后端服务 | 1.21+ |
| GORM | ORM 框架 | v2 |
| gorilla/mux | HTTP 路由 | v1.8 |
| Next.js | Admin Dashboard + API | 14+ |
| TypeScript | 类型安全 | 5.x |

### 移动端

| 技术 | 用途 | 版本 |
|-----|------|------|
| Flutter | 跨平台 UI | 3.x |
| Dart | 开发语言 | 3.x |
| sqflite | 本地数据库 | 2.x |
| provider | 状态管理 | 6.x |

### 数据库

| 数据库 | 优先级 | 说明 |
|-------|-------|------|
| Supabase | 首选 | 云端 PostgreSQL + Auth + Realtime |
| PostgreSQL | 备选 | 自托管 SQL 数据库 |
| MySQL | 备选 | 自托管 SQL 数据库 |
| SQLite | 开发/测试 | 轻量级本地数据库 |

### 基础设施

| 服务 | 用途 |
|-----|------|
| Docker | 容器化部署 |
| Docker Compose | 本地开发环境 |
| Vercel | Next.js 托管 (可选) |
| Supabase | BaaS 服务 (可选) |

---

## 数据流

### 1. 收款通知流程

```
用户付款 -> 微信/支付宝推送通知
     |
     v
+----------------------------------+
|   Mobile Agent (Flutter)         |
|                                  |
|  1. NotificationListener 捕获    |
|  2. PayTransaction.fromEvent()   |
|  3. 存入本地 SQLite              |
|  4. POST /api/v1/records         |
+----------------+-----------------+
                 |
                 v
+----------------------------------+
|      Go Backend Server           |
|                                  |
|  1. 验证 Agent 身份               |
|  2. 创建 PayRecord               |
|  3. 匹配 pending Order           |
|  4. 更新 Order 状态              |
|  5. 回调商户 Callback URL        |
+----------------------------------+
```

### 2. 创建订单流程

```
商户 App -> POST /api/v1/order
     |
     v
+----------------------------------+
|      Go Backend Server           |
|                                  |
|  1. 验证 App 身份                 |
|  2. 调度可用 Agent               |
|  3. 计算最终金额 (+-分)           |
|  4. 创建 Order (pending)         |
|  5. 生成收款码数据                |
+----------------+-----------------+
                 |
                 v
返回订单信息 + 收款码 -> 用户扫码支付
```

### 3. 管理后台数据流

```
Admin Dashboard (Browser)
     |
     | (Server Components / API Routes)
     v
+----------------------------------+
|      Next.js Server              |
|                                  |
|  - Server-Side Rendering         |
|  - API Route handlers            |
|  - 认证中间件                     |
+----------------+-----------------+
                 |
                 | (内部调用 or 直连数据库)
                 v
+----------------------------------+
|   Go Backend / Storage Layer     |
+----------------------------------+
```

---

## 部署架构

### 开发环境

```yaml
# docker-compose.dev.yml
services:
  postgres:
    image: postgres:15
    
  admin:
    build: ./admin
    depends_on: [postgres]
    
  server:
    build: ./server
    depends_on: [postgres]
```

### 生产环境 (Supabase + Vercel)

```
+---------------------------------------------+
|                   Vercel                    |
|                                             |
|  +---------------------------------------+  |
|  |     Next.js Admin Dashboard           |  |
|  |     (SSR + API Routes)                |  |
|  +-----------------+---------------------+  |
|                    |                        |
+--------------------+------------------------+
                     |
          +----------+----------+
          |                     |
          v                     v
+-----------------+    +------------------+
|   Supabase      |    |   Go Backend     |
|                 |    |   (自托管/云)     |
| - PostgreSQL    |    |                  |
| - Auth          |    |  - API Server    |
| - Realtime      |    |  - 业务逻辑       |
| - Storage       |    |                  |
+-----------------+    +------------------+
```

### 自托管环境

```
+---------------------------------------------+
|              Docker Host / K8s              |
|                                             |
|  +---------+  +---------+  +-------------+  |
|  | Nginx   |  | Admin   |  |  Go Server  |  |
|  | (Proxy) |  | (Next)  |  |             |  |
|  +----+----+  +----+----+  +------+------+  |
|       |            |              |         |
|       +------------+--------------+         |
|                    |                        |
|             +------v------+                 |
|             |  PostgreSQL |                 |
|             |  / MySQL    |                 |
|             +-------------+                 |
+---------------------------------------------+
```

---

## 目录结构

```
payserver/
|-- admin/                      # Next.js Admin Dashboard
|   |-- app/                    # App Router (Next.js 14+)
|   |   |-- (auth)/             # 认证相关页面
|   |   |-- (dashboard)/        # 仪表板页面
|   |   |-- api/                # API Routes
|   |   +-- layout.tsx
|   |-- components/             # React 组件
|   |-- lib/                    # 工具函数
|   |   |-- db/                 # 数据库客户端
|   |   |   |-- index.ts        # 统一导出
|   |   |   |-- supabase.ts     # Supabase 客户端
|   |   |   +-- prisma.ts       # Prisma 客户端 (备选)
|   |   +-- api/                # Go Backend API 客户端
|   +-- package.json
|
|-- server/                     # Go Backend
|   |-- apis/                   # API handlers
|   |-- cmd/                    # CLI 命令
|   |-- config/                 # 配置
|   |-- core/                   # 领域模型
|   |-- pkg/                    # 通用包
|   |-- server/                 # 业务逻辑
|   |-- service/                # 服务编排
|   |-- store/                  # 存储层
|   |   |-- store.go            # 接口定义
|   |   |-- config.go           # 存储配置
|   |   |-- msql/               # MySQL/SQLite 实现
|   |   |-- postgres/           # PostgreSQL 实现
|   |   +-- supabase/           # Supabase 实现
|   |-- main.go
|   +-- go.mod
|
|-- agent/                      # Flutter Mobile Agent
|   |-- lib/
|   |   |-- main.dart
|   |   |-- models/             # 数据模型
|   |   |-- pages/              # UI 页面
|   |   |-- services/           # 业务服务
|   |   |-- store/              # 本地存储
|   |   |-- styles/             # 样式
|   |   +-- views/              # 可复用视图
|   |-- android/
|   |-- ios/
|   +-- pubspec.yaml
|
|-- docs/                       # 文档
|   |-- ARCHITECTURE.md         # 本文档
|   |-- ADMIN_DESIGN.md         # Admin 设计
|   |-- STORAGE_DESIGN.md       # 存储层设计
|   |-- AGENT_DESIGN.md         # Agent 设计
|   +-- API.md                  范
|
|-- docker-compose.yml
|-- docker-compose.dev.yml
+-- README.md
```

---

## 下一步

1. [Admin Dashboard 设计](./ADMIN_DESIGN.md) - Next.js 前端详细设计
2. [存储层设计](./STORAGE_DESIGN.md) - 插件化数据库架构
3. [Agent 升级设计](./AGENT_D Flutter 端升级方案
4. [API 规范](./API.md) - RESTful API 接口文档
