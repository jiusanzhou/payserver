# PayServer API 规范

> RESTful API 接口文档 | Version: v1

## 目录

- [概述](#概述)
- [认证](#认证)
- [通用规范](#通用规范)
- [API 端点](#api-端点)
  - [订单 API](#订单-api)
  - [Agent API](#agent-api)
  - [应用 API](#应用-api)
  - [记录 API](#记录-api)
- [Webhook](#webhook)
- [错误码](#错误码)

---

## 概述

PayServer 提供两套 API:

| API | 基础路径 | 说明 |
|-----|----------|------|
| Go Backend API | `/api/v1` | 核心业务 API，处理订单、Agent、收款等 |
| Next.js API | `/api/v1` | Admin Dashboard BFF API |

### 基础 URL

```
# 开发环境
Go Backend: http://localhost:30911/api/v1
Next.js:    http://localhost:3000/api/v1

# 生产环境
Go Backend: https://api.pay.example.com/api/v1
Next.js:    https://admin.pay.example.com/api/v1
```

---

## 认证

### 应用认证 (商户 API)

商户调用 API 时需要提供 App 凭证:

```http
POST /api/v1/order
Content-Type: application/json
X-App-ID: app_xxxxx
X-App-Secret: sk_xxxxx
X-Timestamp: 1700000000
X-Signature: sha256_hmac_signature
```

**签名算法:**

```
signature = HMAC-SHA256(
  key = app_secret,
  message = method + path + timestamp + body
)
```

### Agent 认证

Agent 设备使用 ticket 进行认证:

```http
POST /api/v1/records
Content-Type: application/json
X-Agent-UID: agent_xxxxx
X-Agent-Ticket: tk_xxxxx
```

### Admin 认证

Admin Dashboard 使用 Session/JWT:

```http
GET /api/v1/orders
Authorization: Bearer eyJxxxxx
```

---

## 通用规范

### 请求格式

```http
Content-Type: application/json
Accept: application/json
```

### 响应格式

**成功响应:**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    // 具体数据
  }
}
```

**分页响应:**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "items": [...],
    "total": 100,
    "page": 1,
    "limit": 20
  }
}
```

**错误响应:**

```json
{
  "code": 10001,
  "message": "Invalid parameter",
  "error": "app_id is required"
}
```

### HTTP 状态码

| 状态码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未认证 |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## API 端点

### 订单 API

#### 创建订单

创建一个新的支付订单。

```http
POST /api/v1/order
```

**请求体:**

```json
{
  "number": "ORD202402160001",    // 商户订单号 (必填)
  "name": "商品名称",              // 订单名称 (可选)
  "price": 9900,                  // 金额，单位: 分 (必填)
  "redirect_url": "https://...",  // 支付成功后跳转 (可选)
  "external": "{\"user_id\":123}" // 额外信息 (可选)
}
```

**响应:**

```json
{
  "code": 0,
  "message": "success",
  "data": {
    "uid": "ord_xxxxxxxxxxxxx",
    "app_id": "app_xxxxx",
    "number": "ORD202402160001",
    "price": 9900,
    "sched_price": 9901,          // 实际支付金额 (可能微调)
    "status": "pending",
    "qr_data": "wxp://xxxxx",     // 二维码数据
    "qr_image_url": "https://...",// 二维码图片 URL
    "expires_in": 300,            // 过期时间 (秒)
    "create_at": "2024-02-16T10:00:00Z"
  }
}
```

#### 查询订单

```http
GET /api/v1/order/{uid}
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "uid": "ord_xxxxxxxxxxxxx",
    "app_id": "app_xxxxx",
    "pre_order": {
      "number": "ORD202402160001",
      "name": "商品名称",
      "price": 9900,
      "redirect_url": "https://...",
      "external": "{}"
    },
    "sched_price": 9901,
    "sched_agent_uid": "agent_xxxxx",
    "sched_pay_type": "wechat",
    "status": "paid",
    "pay_record": {
      "uid": "rec_xxxxx",
      "amount": 9901,
      "timestamp": "2024-02-16T10:02:30Z"
    },
    "create_at": "2024-02-16T10:00:00Z",
    "update_at": "2024-02-16T10:02:30Z"
  }
}
```

#### 查询订单状态

轻量级接口，仅返回状态。

```http
GET /api/v1/order/{uid}/status
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "status": "paid"
  }
}
```

#### 取消订单

```http
POST /api/v1/order/{uid}/cancel
```

**响应:**

```json
{
  "code": 0,
  "message": "Order cancelled"
}
```

---

### Agent API

#### 准备注册 Agent

获取注册 ticket。

```http
POST /api/v1/agent/prepare
```

**请求体:**

```json
{
  "device_id": "android_xxxxx",   // 设备唯一标识
  "device_info": "{...}",         // 设备信息 JSON
  "pay_types": "wechat,alipay",   // 支持的支付类型
  "external": "{}"                // 额外信息
}
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "ticket": "tk_xxxxxxxxxxxxx"
  }
}
```

#### 注册 Agent

使用 ticket 完成注册。

```http
POST /api/v1/agents
```

**请求体:**

```json
{
  "ticket": "tk_xxxxxxxxxxxxx",
  "device_id": "android_xxxxx",
  "pay_types": "wechat,alipay"
}
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "uid": "agent_xxxxxxxxxxxxx",
    "device_id": "android_xxxxx",
    "status": "normal",
    "ticket": "tk_xxxxx",
    "create_at": "2024-02-16T10:00:00Z"
  }
}
```

#### 获取 Agent

```http
GET /api/v1/agent/{uid}
```

#### 更新 Agent

```http
POST /api/v1/agent/{uid}
```

**请求体:**

```json
{
  "pay_types": "wechat",
  "status": "normal",
  "external": "{}"
}
```

#### 删除 Agent

```http
DELETE /api/v1/agent/{uid}
```

#### Agent 心跳

```http
POST /api/v1/agent/{uid}/heartbeat
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "status": "normal",
    "heartbeat_at": "2024-02-16T10:00:00Z"
  }
}
```

#### 获取 Agent 列表

```http
GET /api/v1/agents?offset=0&limit=20&status=normal
```

#### 获取 Agent 绑定的应用

```http
GET /api/v1/agent/{uid}/apps
```

#### 获取 Agent 的收款记录

```http
GET /api/v1/agent/{uid}/records?offset=0&limit=20
```

---

### 应用 API

#### 创建应用

```http
POST /api/v1/apps
```

**请求体:**

```json
{
  "name": "我的商城",
  "description": "电商网站",
  "callback_url": "https://example.com/webhook/pay",
  "price_floor": 20,       // 价格下浮，单位: 分
  "price_ceil": 0,         // 价格上浮，单位: 分
  "expire_in": 300,        // 订单过期时间，秒
  "max_pendding_order": 10 // 最大等待订单数
}
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "uid": "app_xxxxxxxxxxxxx",
    "name": "我的商城",
    "secret": "sk_xxxxxxxxxxxxx",
    "aes_key": "ak_xxxxxxxxxxxxx",
    "callback_url": "https://example.com/webhook/pay",
    "create_at": "2024-02-16T10:00:00Z"
  }
}
```

#### 获取应用列表

```http
GET /api/v1/apps?offset=0&limit=20
```

#### 获取应用详情

```http
GET /api/v1/app/{uid}
```

#### 更新应用

```http
POST /api/v1/app/{uid}
```

#### 删除应用

```http
DELETE /api/v1/app/{uid}
```

#### 获取应用绑定的 Agent

```http
GET /api/v1/app/{uid}/agents
```

#### 为应用绑定 Agent

```http
POST /api/v1/app/{uid}/agents
```

**请求体:**

```json
{
  "agent_uid": "agent_xxxxx",
  "weight": 10
}
```

#### 更新应用的 Agent 绑定

```http
POST /api/v1/app/{app_uid}/agent/{agent_uid}
```

**请求体:**

```json
{
  "weight": 20
}
```

#### 解绑 Agent

```http
DELETE /api/v1/app/{app_uid}/agent/{agent_uid}
```

#### 获取应用的收款记录

```http
GET /api/v1/app/{uid}/records?offset=0&limit=20
```

---

### 记录 API

#### 创建收款记录

Agent 上报收款记录。

```http
POST /api/v1/records
```

**请求体:**

```json
{
  "type": "wechat",              // 支付类型: wechat, alipay
  "number": "4200001234567890",  // 平台流水号
  "amount": 9901,                // 金额，单位: 分
  "timestamp": 1700000000000,    // 时间戳，毫秒
  "external": "{}"               // 额外信息
}
```

**响应:**

```json
{
  "code": 0,
  "data": {
    "uid": "rec_xxxxxxxxxxxxx",
    "agent_uid": "agent_xxxxx",
    "type": "wechat",
    "amount": 9901,
    "matched_order": {
      "uid": "ord_xxxxx",
      "number": "ORD202402160001"
    },
    "create_at": "2024-02-16T10:02:30Z"
  }
}
```

#### 获取收款记录

```http
GET /api/v1/record/{uid}
```

#### 获取收款记录列表

```http
GET /api/v1/records?offset=0&limit=20&type=wechat&from=2024-02-01&to=2024-02-29
```

---

## Webhook

当订单状态变更时，系统会向应用配置的 `callback_url` 发送 HTTP POST 请求。

### 请求格式

```http
POST {callback_url}
Content-Type: application/json
X-Signature: sha256_hmac_signature
X-Timestamp: 1700000000
```

**请求体:**

```json
{
  "event": "order.paid",
  "data": {
    "order_uid": "ord_xxxxxxxxxxxxx",
    "order_number": "ORD202402160001",
    "amount": 9901,
    "pay_type": "wechat",
    "paid_at": "2024-02-16T10:02:30Z"
  },
  "timestamp": 1700000000
}
```

### 事件类型

| 事件 | 说明 |
|------|------|
| `order.paid` | 订单已支付 |
| `order.expired` | 订单已过期 |
| `order.cancelled` | 订单已取消 |

### 签名验证

```
signature = HMAC-SHA256(
  key = app_secret,
  message = timestamp + request_body
)
```

### 重试策略

| 重试次数 | 间隔 |
|----------|------|
| 第 1 次 | 立即 |
| 第 2 次 | 5 秒 |
| 第 3 次 | 30 秒 |
| 第 4 次 | 5 分钟 |
| 第 5 次 | 30 分钟 |

如果 5 次重试后仍失败，将停止重试。

---

## 错误码

### 通用错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 10001 | 参数错误 |
| 10002 | 签名错误 |
| 10003 | 时间戳过期 |
| 10004 | 请求频率过高 |

### 认证错误码

| 错误码 | 说明 |
|--------|------|
| 20001 | App ID 不存在 |
| 20002 | App Secret 错误 |
| 20003 | Agent 未注册 |
| 20004 | Agent Ticket 错误 |
| 20005 | 无权限访问 |

### 订单错误码

| 错误码 | 说明 |
|--------|------|
| 30001 | 订单不存在 |
| 30002 | 订单已过期 |
| 30003 | 订单已支付 |
| 30004 | 订单已取消 |
| 30005 | 无可用 Agent |
| 30006 | 超过最大等待订单数 |
| 30007 | 订单号重复 |

### Agent 错误码

| 错误码 | 说明 |
|--------|------|
| 40001 | Agent 不存在 |
| 40002 | Agent 已禁用 |
| 40003 | Agent 离线 |
| 40004 | 设备 ID 已注册 |
| 40005 | Ticket 无效或已过期 |
| 40006 | 超过最大等待注册数 |

### 应用错误码

| 错误码 | 说明 |
|--------|------|
| 50001 | 应用不存在 |
| 50002 | 应用名称已存在 |
| 50003 | Agent 未绑定 |
| 50004 | Agent 已绑定 |

---

## SDK 示例

### Go SDK

```go
package payserver

import (
    "bytes"
    "crypto/hmac"
    "crypto/sha256"
    "encoding/hex"
    "encoding/json"
    "fmt"
    "net/http"
    "strconv"
    "time"
)

type Client struct {
    BaseURL   string
    AppID     string
    AppSecret string
}

func (c *Client) CreateOrder(req *CreateOrderRequest) (*Order, error) {
    body, _ := json.Marshal(req)
    timestamp := strconv.FormatInt(time.Now().Unix(), 10)
    
    signature := c.sign("POST", "/api/v1/order", timestamp, body)
    
    httpReq, _ := http.NewRequest("POST", c.BaseURL+"/api/v1/order", bytes.NewReader(body))
    httpReq.Header.Set("Content-Type", "application/json")
    httpReq.Header.Set("X-App-ID", c.AppID)
    httpReq.Header.Set("X-Timestamp", timestamp)
    httpReq.Header.Set("X-Signature", signature)
    
    resp, err := http.DefaultClient.Do(httpReq)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    var result struct {
        Code    int    `json:"code"`
        Message string `json:"message"`
        Data    Order  `json:"data"`
    }
    json.NewDecoder(resp.Body).Decode(&result)
    
    if result.Code != 0 {
        return nil, fmt.Errorf("API error: %s", result.Message)
    }
    
    return &result.Data, nil
}

func (c *Client) sign(method, path, timestamp string, body []byte) string {
    message := method + path + timestamp + string(body)
    h := hmac.New(sha256.New, []byte(c.AppSecret))
    h.Write([]byte(message))
    return hex.EncodeToString(h.Sum(nil))
}
```

### JavaScript SDK

```javascript
const crypto = require('crypto');

class PayServerClient {
  constructor(baseURL, appID, appSecret) {
    this.baseURL = baseURL;
    this.appID = appID;
    this.appSecret = appSecret;
  }

  async createOrder({ number, name, price, redirectUrl, external }) {
    const body = JSON.stringify({ number, name, price, redirect_url: redirectUrl, external });
    const timestamp = Math.floor(Date.now() / 1000).toString();
    const signature = this.sign('POST', '/api/v1/order', timestamp, body);

    const response = await fetch(`${this.baseURL}/api/v1/order`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-App-ID': this.appID,
        'X-Timestamp': timestamp,
        'X-Signature': signature,
      },
      body,
    });

    const result = await response.json();
    if (result.code !== 0) {
      throw new Error(result.message);
    }
    return result.data;
  }

  sign(method, path, timestamp, body) {
    const message = method + path + timestamp + body;
    return crypto.createHmac('sha256', this.appSecret).update(message).digest('hex');
  }

  // 验证 Webhook 签名
  verifyWebhook(signature, timestamp, body) {
    const expected = crypto
      .createHmac('sha256', this.appSecret)
      .update(timestamp + body)
      .digest('hex');
    return signature === expected;
  }
}

module.exports = PayServerClient;
```

---

## 注意事项

1. **幂等性**: 使用相同的 `number` 重复创建订单会返回错误
2. **时间戳**: 请求时间戳与服务器时间差不能超过 5 分钟
3. **编码**: 所有请求和响应使用 UTF-8 编码
4. **金额**: 所有金额单位为「分」，整数
5. **时间**: 所有时间使用 ISO 8601 格式 (UTC)
