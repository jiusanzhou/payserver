/**
 * PayServer Core Types
 * Mirrors Go server/core types
 */

// Order status constants
export const OrderStatus = {
  Pending: 1,
  Paid: 2,
  Expired: 3,
  Canceled: 4,
  Unknown: 5,
} as const

export type OrderStatusType = (typeof OrderStatus)[keyof typeof OrderStatus]

export const OrderStatusLabels: Record<number, string> = {
  1: "pending",
  2: "paid",
  3: "expired",
  4: "canceled",
  5: "unknown",
}

// Agent status constants
export const AgentStatus = {
  Normal: 1,
  Offline: 2,
  Disabled: 3,
  Pending: 4,
  Busy: 5,
  Unknown: 6,
} as const

export type AgentStatusType = (typeof AgentStatus)[keyof typeof AgentStatus]

// Callback status constants
export const CallbackStatus = {
  Pending: 1,
  Success: 2,
  Failed: 3,
} as const

export type CallbackStatusType = (typeof CallbackStatus)[keyof typeof CallbackStatus]

// Pay types
export const PayType = {
  WeChat: "wechat",
  Alipay: "alipay",
} as const

export type PayTypeType = (typeof PayType)[keyof typeof PayType]

export function isSupportedPayType(method: string): boolean {
  return method === PayType.WeChat || method === PayType.Alipay
}

// Retry intervals for callbacks (in seconds)
export const RetryIntervals = [15, 30, 60, 120, 240]
export const MaxRetryAttempts = 5

export function calculateNextRetry(attempt: number): Date | null {
  if (attempt >= MaxRetryAttempts) {
    return null
  }
  const interval = RetryIntervals[attempt]
  return new Date(Date.now() + interval * 1000)
}

// Model interfaces
export interface Model {
  id?: number
  uid: string
  create_at: string
  update_at: string
  deleted_at?: string | null
}

export interface PreOrder {
  number: string
  name: string
  price: number
  redirect_url: string
  external: string
}

export interface Order extends Model {
  app_id: string
  pre_order: PreOrder
  expires_in: number
  qr_data: string
  qr_image_url: string
  sched_agent_uid: string
  sched_pay_type: string
  sched_price: number
  pay_record_uid?: string | null
  status: OrderStatusType
}

export interface Agent extends Model {
  device_id: string
  pay_types: string
  heartbeat_at: string
  status: AgentStatusType
  ticket: string
  device_info: string
  external: string
}

export interface App extends Model {
  name: string
  description: string
  callback_url: string
  secret: string
  aes_key: string
  price_floor: number
  price_ceil: number
  expire_in: number
  max_pendding_order: number
  user_uid: string
  agents?: Agent[]
}

export interface PayRecord extends Model {
  agent_uid: string
  type: string
  number: string
  amount: number
  timestamp: string
  account_uid: string
  external: string
}

export interface CallbackLog extends Model {
  order_uid: string
  app_id: string
  callback_url: string
  payload: string
  status: CallbackStatusType
  attempts: number
  max_attempts: number
  last_error: string
  last_response: string
  last_attempt?: string | null
  next_attempt?: string | null
}

export interface AppAgentBind {
  id?: number
  app_uid: string
  agent_uid: string
  weight: number
  created_at?: string
  deleted_at?: string | null
}

export interface RegisterAgentTicket {
  name: string
  host: string
  version: string
  ticket: string
}
