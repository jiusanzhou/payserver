<div align="center">

# PayServer

**个人收款解决方案 —— 让收款更简单**

[![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)](https://go.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?logo=flutter)](https://flutter.dev/)
[![Next.js](https://img.shields.io/badge/Next.js-14+-000000?logo=next.js)](https://nextjs.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

---

## 简介

PayServer 是一个完整的个人收款解决方案，由三个核心组件组成：

- **Server** - Go 后端 API 服务，处理订单、记录匹配、Webhook 回调
- **Admin** - Next.js 管理后台，订单/应用/Agent 管理，数据统计
- **Agent** - Flutter 移动应用，监听支付通知并上报服务端

## 特点

- 🔔 **实时通知** - 设备收到付款时立即通知后端服务
- 🔌 **插件化存储** - 支持 Supabase / PostgreSQL / MySQL
- 📱 **移动端采集** - Flutter Agent 后台监听通知
- 🎛️ **管理后台** - 现代化 Next.js Dashboard
- 🔐 **安全认证** - JWT + Supabase Auth
- 🚀 **易于部署** - 支持 SaaS 和自托管
- ✍️ **手动录入** - 支持手动补录收款记录
- 🔋 **后台保活** - 支持电池优化白名单和开机自启

## 架构

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Agent     │────▶│   Server    │◀────│   Admin     │
│  (Flutter)  │     │  (Next.js)  │     │  (Next.js)  │
└─────────────┘     └──────┬──────┘     └─────────────┘
                           │
                    ┌──────▼──────┐
                    │  Database   │
                    │ (Supabase)  │
                    └─────────────┘
```

## 预览

|开始|选择服务|添加服务|关于|
|:---:|:---:|:---:|:---:|
|![Stat Pannel](./assets/home.jpg)|![Change Server](./assets/server-selector.jpg)|![Add Server](./assets/edit-server.jpg)|![About](./assets/about.jpg)|

## 快速开始

### Admin (含 API 服务)

```bash
cd admin
cp .env.example .env.local
# 编辑 .env.local 配置 Supabase
pnpm install
pnpm dev
```

### Agent

```bash
cd agent
flutter pub get
flutter run
```

### Server (可选，Go 后端)

```bash
cd server
cp .env.example .env
# 编辑 .env 配置数据库连接
go run main.go
```

## 核心功能

### 订单流程

1. **创建订单** - 外部应用通过 API 创建待支付订单
2. **调度 Agent** - 系统自动选择可用 Agent 和支付方式
3. **监听收款** - Agent 监听支付宝/微信收款通知
4. **自动匹配** - 收款记录与待支付订单自动匹配
5. **回调通知** - 支付成功后触发 Webhook 回调

### 手动录入

- Admin 后台：收款记录页面支持手动录入
- Agent 端：首页 FAB 按钮支持手动录入收款
- 支持选择支付渠道（微信/支付宝）和输入金额

### 后台保活

Agent 支持以下保活机制：
- 前台服务通知
- 电池优化白名单
- 开机自动启动
- 定时心跳上报

## 项目结构

```
payserver/
├── server/          # Go 后端 (可选)
│   ├── apis/        # HTTP handlers
│   ├── core/        # 核心业务逻辑
│   ├── server/      # HTTP server
│   └── store/       # 存储层 (postgres/supabase/mysql)
├── admin/           # Next.js 管理后台 + API
│   ├── app/         # App Router
│   ├── components/  # UI 组件
│   └── lib/         # 服务层 + 工具库
├── agent/           # Flutter 移动端
│   ├── lib/core/    # 核心服务 (监听/电池)
│   ├── lib/data/    # 数据层 (API/数据库)
│   └── lib/presentation/  # UI (页面/组件)
└── docs/            # 文档
```

## API 示例

### 创建订单

```bash
curl -X POST "http://localhost:3000/api/v1/order?appid=YOUR_APP_ID&method=wechat" \
  -H "Content-Type: application/json" \
  -d '{
    "number": "ORDER-001",
    "name": "测试商品",
    "price": 1999,
    "redirect_url": "https://example.com/success"
  }'
```

### 上报收款 (Agent)

```bash
curl -X POST "http://localhost:3000/api/v1/records" \
  -H "Content-Type: application/json" \
  -d '{
    "agent_uid": "YOUR_AGENT_UID",
    "type": "wechat",
    "amount": 1999,
    "number": "WX-PAY-001"
  }'
```

### 查询订单状态

```bash
curl "http://localhost:3000/api/v1/order/ORDER_UID/status"
# 返回: {"status": 2}  // 1=pending, 2=paid, 3=expired, 4=canceled
```

## 文档

| 文档 | 说明 |
|------|------|
| [架构设计](./docs/ARCHITECTURE.md) | 系统整体架构设计 |
| [API 规范](./docs/API.md) | RESTful API 接口文档 |
| [存储层设计](./docs/STORAGE_DESIGN.md) | 插件化数据库架构 |
| [Admin 设计](./docs/ADMIN_DESIGN.md) | 管理后台设计 |
| [Agent 设计](./docs/AGENT_DESIGN.md) | Flutter 端设计 |

## 技术栈

| 组件 | 技术 |
|------|------|
| Server | Go 1.21+, gorilla/mux, GORM |
| Admin | Next.js 14, React, Tailwind CSS, Supabase |
| Agent | Flutter 3.10+, Riverpod, Drift |
| Database | Supabase / PostgreSQL / MySQL |

## Roadmap

- [x] Go 后端核心 API
- [x] 插件化存储层
- [x] Flutter Agent 通知监听
- [x] Next.js Admin 基础框架
- [x] Next.js API 服务层
- [x] 手动录入收款记录
- [x] Agent 后台保活 (电池优化/开机启动)
- [x] 收款记录列表页
- [ ] Admin Dashboard 数据可视化
- [ ] Agent 扫码绑定
- [ ] Webhook 重试调度器
- [ ] 多 Agent 负载均衡

## License

MIT
