# Admin Dashboard 设计文档

> 基于 Next.js 14+ App Router 的管理后台前端设计

## 目录

- [概述](#概述)
- [技术选型](#技术选型)
- [项目结构](#项目结构)
- [页面设计](#页面设计)
- [API 设计](#api-设计)
- [认证方案](#认证方案)
- [数据库访问](#数据库访问)
- [状态管理](#状态管理)
- [部署方案](#部署方案)

---

## 概述

Admin Dashboard 是 PayServer 的管理后台，提供:

- 数据可视化仪表板
- 订单管理
- Agent 设备管理
- 应用管理
- 收款记录查询
- 数据分析报表
- 系统配置

### 设计原则

1. **Server-First**: 优先使用 Server Components，减少客户端 JS
2. **Type-Safe**: 全量 TypeScript，端到端类型安全
3. **Responsive**: 响应式设计，支持移动端访问
4. **Real-time**: 关键数据实时更新（借助 Supabase Realtime）

---

## 技术选型

| 技术 | 用途 | 选择理由 |
|-----|------|----------|
| Next.js 14+ | 框架 | App Router、Server Components、API Routes |
| TypeScript | 语言 | 类型安全 |
| Tailwind CSS | 样式 | 快速开发、响应式 |
| shadcn/ui | UI 组件 | 高质量、可定制、Radix 基础 |
| React Query | 数据请求 | 缓存、乐观更新、实时同步 |
| Zustand | 状态管理 | 轻量、简单 |
| Supabase Client | 数据库 | 直连 PostgreSQL、实时订阅 |
| NextAuth.js | 认证 | 多种认证方式、Session 管理 |
| Recharts | 图表 | React 友好、声明式 |

---

## 项目结构

```
admin/
|-- app/
|   |-- (auth)/                     # 认证相关（无需登录）
|   |   |-- login/
|   |   |   +-- page.tsx
|   |   |-- register/
|   |   |   +-- page.tsx
|   |   +-- layout.tsx
|   |
|   |-- (dashboard)/                # 仪表板（需要登录）
|   |   |-- page.tsx                # 首页 Dashboard
|   |   |-- orders/
|   |   |   |-- page.tsx            # 订单列表
|   |   |   +-- [id]/
|   |   |       +-- page.tsx        # 订单详情
|   |   |-- agents/
|   |   |   |-- page.tsx            # Agent 列表
|   |   |   +-- [id]/
|   |   |       +-- page.tsx        # Agent 详情
|   |   |-- apps/
|   |   |   |-- page.tsx            # 应用列表
|   |   |   |-- new/
|   |   |   |   +-- page.tsx        # 创建应用
|   |   |   +-- [id]/
|   |   |       |-- page.tsx        # 应用详情
|   |   |       +-- edit/
|   |   |           +-- page.tsx    # 编辑应用
|   |   |-- records/
|   |   |   +-- page.tsx            # 收款记录
|   |   |-- analytics/
|   |   |   +-- page.tsx            # 数据分析
|   |   |-- settings/
|   |   |   +-- page.tsx            # 系统设置
|   |   +-- layout.tsx              # Dashboard 布局
|   |
|   |-- api/                        # API Routes
|   |   |-- auth/
|   |   |   +-- [...nextauth]/
|   |   |       +-- route.ts        # NextAuth handler
|   |   |-- v1/
|   |   |   |-- orders/
|   |   |   |   +-- route.ts
|   |   |   |-- agents/
|   |   |   |   +-- route.ts
|   |   |   |-- apps/
|   |   |   |   +-- route.ts
|   |   |   |-- records/
|   |   |   |   +-- route.ts
|   |   |   +-- stats/
|   |   |       +-- route.ts
|   |   +-- webhook/
|   |       +-- route.ts            # Go Backend webhook
|   |
|   |-- layout.tsx                  # Root layout
|   |-- globals.css
|   +-- providers.tsx               # Client providers
|
|-- components/
|   |-- ui/                         # shadcn/ui 组件
|   |   |-- button.tsx
|   |   |-- card.tsx
|   |   |-- table.tsx
|   |   +-- ...
|   |-- layout/
|   |   |-- sidebar.tsx
|   |   |-- header.tsx
|   |   +-- nav.tsx
|   |-- dashboard/
|   |   |-- stats-card.tsx
|   |   |-- recent-orders.tsx
|   |   +-- agent-status.tsx
|   |-- orders/
|   |   |-- order-table.tsx
|   |   |-- order-detail.tsx
|   |   +-- order-filters.tsx
|   |-- agents/
|   |   |-- agent-list.tsx
|   |   |-- agent-card.tsx
|   |   +-- agent-status-badge.tsx
|   |-- apps/
|   |   |-- app-form.tsx
|   |   +-- app-card.tsx
|   +-- charts/
|       |-- revenue-chart.tsx
|       +-- orders-chart.tsx
|
|-- lib/
|   |-- db/
|   |   |-- index.ts                # 统一导出
|   |   |-- supabase.ts             # Supabase 客户端
|   |   |-- prisma.ts               # Prisma 客户端 (备选)
|   |   +-- queries/
|   |       |-- orders.ts
|   |       |-- agents.ts
|   |       |-- apps.ts
|   |       +-- records.ts
|   |-- api/
|   |   |-- client.ts               # Go Backend API 客户端
|   |   +-- types.ts
|   |-- auth/
|   |   |-- options.ts              # NextAuth 配置
|   |   +-- utils.ts
|   |-- utils/
|   |   |-- format.ts               # 格式化工具
|   |   +-- cn.ts                   # className 合并
|   +-- validations/
|       |-- order.ts
|       |-- app.ts
|       +-- agent.ts
|
|-- hooks/
|   |-- use-orders.ts
|   |-- use-agents.ts
|   +-- use-realtime.ts
|
|-- types/
|   |-- order.ts
|   |-- agent.ts
|   |-- app.ts
|   +-- record.ts
|
|-- middleware.ts                   # 认证中间件
|-- next.config.js
|-- tailwind.config.js
|-- tsconfig.json
+-- package.json
```

---

## 页面设计

### 1. Dashboard 首页

```
+------------------------------------------------------------------+
| LOGO   PayServer                                    [User Menu]   |
+----------+-------------------------------------------------------+
|          |                                                        |
| [x] Home |   Today's Overview                                     |
| Orders   |   +------------+ +------------+ +------------+ +-----+ |
| Agents   |   | Revenue    | | Orders     | | Agents     | | ... | |
| Apps     |   | Y12,345.00 | | 156        | | 8 Online   | |     | |
| Records  |   +------------+ +------------+ +------------+ +-----+ |
| Analytics|                                                        |
| -------- |   Recent Orders                                        |
| Settings |   +--------------------------------------------------+ |
|          |   | # | Order ID | Amount | Status | Time    | App   | |
|          |   +--------------------------------------------------+ |
|          |   | 1 | xxx-001  | Y99.00 | Paid   | 10:30   | Demo  | |
|          |   | 2 | xxx-002  | Y15.50 | Pending| 10:28   | Shop  | |
|          |   +--------------------------------------------------+ |
|          |                                                        |
|          |   Agent Status           Revenue Trend                 |
|          |   +------------------+   +-------------------------+   |
|          |   | [Chart]          |   | [Line Chart]            |   |
|          |   +------------------+   +-------------------------+   |
+----------+-------------------------------------------------------+
```

### 2. Orders 订单管理

```
+------------------------------------------------------------------+
| Orders                                          [+ Create Order]  |
+------------------------------------------------------------------+
| Filters: [All Status v] [All Apps v] [Date Range] [Search...]     |
+------------------------------------------------------------------+
| +----------------------------------------------------------------+|
| | Order ID     | Amount  | Status  | App    | Agent  | Created   ||
| +----------------------------------------------------------------+|
| | ord_xxx001   | Y99.00  | [Paid]  | Demo   | Agent1 | 2h ago    ||
| | ord_xxx002   | Y15.50  | [Pending| Shop   | Agent2 | 3h ago    ||
| | ord_xxx003   | Y299.00 | [Expired| Demo   | Agent1 | 1d ago    ||
| +----------------------------------------------------------------+|
| [< Prev]                    Page 1 of 10                 [Next >] |
+------------------------------------------------------------------+
```

### 3. Agents 设备管理

```
+------------------------------------------------------------------+
| Agents                                                            |
+------------------------------------------------------------------+
| Online: 8  |  Offline: 2  |  Pending: 1                           |
+------------------------------------------------------------------+
| +------------------------+ +------------------------+             |
| | Agent: iPhone-001      | | Agent: Android-002     |             |
| | Status: [Online]       | | Status: [Offline]      |             |
| | Pay Types: Wechat,Ali  | | Pay Types: Wechat      |             |
| | Last Active: Just now  | | Last Active: 2h ago    |             |
| | Bound Apps: 2          | | Bound Apps: 1          |             |
| | [View] [Edit] [Remove] | | [View] [Edit] [Remove] |             |
| +------------------------+ +------------------------+             |
+------------------------------------------------------------------+
```

### 4. Apps 应用管理

```
+------------------------------------------------------------------+
| Applications                                       [+ New App]    |
+------------------------------------------------------------------+
| +----------------------------------------------------------------+|
| | App Name    | App ID       | Agents | Callback URL    | Status ||
| +----------------------------------------------------------------+|
| | Demo App    | app_xxx001   | 3      | https://...     | Active ||
| | Test Shop   | app_xxx002   | 1      | https://...     | Active ||
| +----------------------------------------------------------------+|
+------------------------------------------------------------------+

App Detail:
+------------------------------------------------------------------+
| Demo App                                              [Edit]      |
+------------------------------------------------------------------+
| App ID: app_xxx001                                                |
| Secret: ********** [Show] [Regenerate]                            |
| Callback URL: https://merchant.com/webhook                        |
| Price Range: -Y0.20 ~ +Y0.00                                      |
| Order Expire: 300s                                                |
| Max Pending Orders: 10                                            |
+------------------------------------------------------------------+
| Bound Agents:                                                     |
| +----------------------------+ +----------------------------+     |
| | Agent: iPhone-001 [Online] | | Agent: Android-002 [Offline|     |
| | Weight: 10                 | | Weight: 5                  |     |
| | [Unbind]                   | | [Unbind]                   |     |
| +----------------------------+ +----------------------------+     |
|                                              [+ Bind Agent]       |
+------------------------------------------------------------------+
```

---

## API 设计

### Next.js API Routes

Admin Dashboard 的 API Routes 主要用于:

1. **BFF 聚合**: 聚合多个 Go Backend API 调用
2. **数据转换**: 适配前端数据格式
3. **缓存处理**: 实现请求级缓存
4. **直连数据库**: 简单查询直接访问 Supabase

```typescript
// app/api/v1/stats/route.ts
import { createClient } from '@/lib/db/supabase'
import { NextResponse } from 'next/server'

export async function GET() {
  const supabase = createClient()
  
  // 并行查询多个统计数据
  const [orders, agents, revenue] = await Promise.all([
    supabase.from('orders').select('count').eq('status', 'paid'),
    supabase.from('agents').select('count').eq('status', 'normal'),
    supabase.from('orders')
      .select('sched_price')
      .eq('status', 'paid')
      .gte('created_at', todayStart)
  ])
  
  return NextResponse.json({
    todayOrders: orders.count,
    onlineAgents: agents.count,
    todayRevenue: revenue.data?.reduce((sum, o) => sum + o.sched_price, 0)
  })
}
```

### API Routes 规范

| 路由 | 方法 | 说明 |
|------|------|------|
| `/api/v1/orders` | GET | 获取订单列表 |
| `/api/v1/orders` | POST | 创建订单 |
| `/api/v1/orders/[id]` | GET | 获取订单详情 |
| `/api/v1/orders/[id]/cancel` | POST | 取消订单 |
| `/api/v1/agents` | GET | 获取 Agent 列表 |
| `/api/v1/agents/[id]` | GET/PUT/DELETE | Agent CRUD |
| `/api/v1/apps` | GET/POST | 应用列表/创建 |
| `/api/v1/apps/[id]` | GET/PUT/DELETE | 应用 CRUD |
| `/api/v1/apps/[id]/agents` | GET/POST | 绑定的 Agent |
| `/api/v1/records` | GET | 收款记录列表 |
| `/api/v1/stats` | GET | 统计数据 |

### 与 Go Backend 的关系

```
+------------------+       +------------------+       +------------------+
|   Browser        |       |   Next.js        |       |   Go Backend     |
|                  |       |   API Routes     |       |                  |
|  Admin Dashboard |------>|                  |------>|   /api/v1/*      |
|                  |       |  - 认证检查       |       |                  |
+------------------+       |  - 数据聚合       |       +------------------+
                           |  - 格式转换       |                |
                           +------------------+                |
                                    |                          v
                                    |               +------------------+
                                    +-------------->|   Supabase       |
                                    (直连数据库)     |   PostgreSQL     |
                                                    +------------------+
```

**决策原则**:

1. **读取操作**: 优先直连 Supabase（性能更好）
2. **写入操作**: 通过 Go Backend（保证业务逻辑一致性）
3. **复杂业务**: 通过 Go Backend（如创建订单需要调度 Agent）
4. **简单 CRUD**: 可直连 Supabase

---

## 认证方案

使用 NextAuth.js 实现认证:

```typescript
// lib/auth/options.ts
import { NextAuthOptions } from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'
import { createClient } from '@/lib/db/supabase'

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'Credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' }
      },
      async authorize(credentials) {
        const supabase = createClient()
        const { data, error } = await supabase.auth.signInWithPassword({
          email: credentials?.email!,
          password: credentials?.password!
        })
        
        if (error || !data.user) return null
        
        return {
          id: data.user.id,
          email: data.user.email,
          name: data.user.user_metadata?.name
        }
      }
    })
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id
      }
      return token
    },
    async session({ session, token }) {
      session.user.id = token.id as string
      return session
    }
  },
  pages: {
    signIn: '/login'
  }
}
```

### 路由保护

```typescript
// middleware.ts
import { withAuth } from 'next-auth/middleware'

export default withAuth({
  pages: {
    signIn: '/login'
  }
})

export const config = {
  matcher: ['/(dashboard)/:path*']
}
```

---

## 数据库访问

### Supabase 客户端

```typescript
// lib/db/supabase.ts
import { createServerClient, createBrowserClient } from '@supabase/ssr'
import { cookies } from 'next/heaServer-side client
export function createClient() {
  const cookieStore = cookies()
  
  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        get(name: string) {
          return cookieStore.get(name)?.value
        }
      }
    }
  )
}

// Client-side client
export function createBrowserSupabaseClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
  )
}
```

### 查询封装

```typescript
// lib/db/queries/orders.ts
import { createClient } from '../supabase'
import type { Order, OrderStatus } from '@/types/order'

export async function getOrders(params: {
  status?: OrderStatus
  appId?: string
  page?: number
  limit?: number
}) {
  const supabase = createClient()
  const { status, appId, page = 1, limit = 20 } = params
  
  let query = supabase
    .from('orders')
    .select('*, app:apps(name), agent:agents(device_id)', { count: 'exact' })
    .order('created_at', { ascending: false })
    .range((page - 1) * limit, page * limit - 1)
  
  if (status) {
    query = query.eq('status', status)
  }
  
  if (appId) {
    query = query.eq('app_id', appId)
  }
  
  const { data, count, error } = await query
  
  if (error) throw error
  
  return { orders: data as Order[], total: count ?? 0 }
}
```

---

## 状态管理

### Server Components 优先

大部分页面使用 Server Components 直接获取数据:

```typescript
// app/(dashboard)/orders/page.tsx
import { getOrders } from '@/lib/db/queries/orders'
import { OrderTable } from '@/components/orders/order-table'

export default async function OrdersPage({
  searchParams
}: {
  searchParams: { status?: string; page?: string }
}) {
  const { orders, total } = await getOrders({
    status: searchParams.status as any,
    page: Number(searchParams.page) || 1
  })
  
  return (
    <div>
      <h1>Orders</h1>
      <OrderTable orders={orders} total={total} />
    </div>
  )
}
```

### Client State (Zustand)

用于客户端交互状态:

```typescript
// stores/ui.ts
import { create } from 'zustand'

interface UIState {
  sidebarOpen: boolean
  toggleSidebar: () => void
}

export const useUIStore = create<UIState>((set) => ({
  sidebarOpen: true,
  toggleSidebar: () => set((state) => ({ sidebarOpen: !state.sidebarOpen }))
}))
```

### 实时数据 (Supabase Realtime)

```typescript
// hooks/use-realtime.ts
import { useEffect, useState } from 'react'
import { createBrowserSupabaseClient } from '@/lib/db/supabase'
import type { Order } from '@/types/order'

export function useRealtimeOrders(initialOrders: Order[]) {
  const [orders, setOrders] = useState(initialOrders)
  
  useEffect(() => {
    const supabase = createBrowserSupabaseClient()
    
    const channel = supabase
      .channel('orders')
      .on('postgres_changes', 
        { event: '*', schema: 'public', table: 'orders' },
        (payload) => {
          if (payload.eventType === 'INSERT') {
            setOrders(prev => [payload.new as Order, ...prev])
          } else if (payload.eventType === 'UPDATE') {
            setOrders(prev => 
              prev.map(o => o.id === payload.new.id ? payload.new as Order : o)
            )
          }
        }
      )
      .subscribe()
    
    return () => {
      supabase.removeChannel(channel)
    }
  }, [])
  
  return orders
}
```

---

## 部署方案

### Vercel 部署

```yaml
# vercel.json
{
  "buildCommand": "pnpm build",
  "outputDirectory": ".next",
  "framework": "nextjs",
  "env": {
    "NEXT_PUBLIC_SUPABASE_URL": "@supabase-url",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY": "@supabase-anon-key",
    "SUPABASE_SERVICE_ROLE_KEY": "@supabase-service-key",
    "NEXTAUTH_SECRET": "@nextauth-secret",
    "GO_BACKEND_URL": "@go-backend-url"
  }
}
```

### Docker 部署

```dockerfile
# Dockerfile
FROM node:20-alpine AS base

FROM base AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN npm install -g pnpm && pnpm install --frozen-lockfile

FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM base AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

EXPOSE 3000
CMD ["node", "server.js"]
```

### 环境变量

```bash
# .env.local
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJxxx
SUPABASE_SERVICE_ROLE_KEY=eyJxxx

# NextAuth
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key

# Go Backend
GO_BACKEND_URL=http://localhost:30911

# Optional: Prisma (if using PostgreSQL directly)
DATABASE_URL=postgresql://user:pass@localhost:5432/payserver
```

---

## 开发指南

### 快速开始

```bash
# 安装依赖
pnpm install

# 启动开发服务器
pnpm dev

# 构建
pnpm build

# 启动生产服务器
pnpm start
```

### 添加新页面

1. 在 `app/(dashboard)/` 下创建目录和 `page.tsx`
2. 添加对应的 API Route（如需要）
3. 创建所需组件到 `components/`
4. 添加数据库查询到 `lib/db/queries/`

### 添加新组件

```bash
# 使用 shadcn/ui 添加组件
npx shadcn-ui@latest add button
npx shadcn-ui@latest add card
npx shadcn-ui@latest add table
```

---

## 下一步

- [存储层设计](./STORAGE_DESIGN.md) - 了解数据库插件架构
- [API 规范](./API.md) - 完整的 API 接口文档
