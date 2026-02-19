import type { PayType } from "./record"

export type OrderStatus = "pending" | "paid" | "expired" | "canceled" | "unknown"

export const OrderStatusMap: Record<number, OrderStatus> = {
  1: "pending",
  2: "paid",
  3: "expired",
  4: "canceled",
  5: "unknown",
}

export const OrderStatusLabel: Record<OrderStatus, string> = {
  pending: "待支付",
  paid: "已支付",
  expired: "已过期",
  canceled: "已取消",
  unknown: "未知",
}

export const OrderStatusColor: Record<OrderStatus, string> = {
  pending: "bg-yellow-100 text-yellow-800",
  paid: "bg-green-100 text-green-800",
  expired: "bg-gray-100 text-gray-800",
  canceled: "bg-red-100 text-red-800",
  unknown: "bg-gray-100 text-gray-600",
}

export interface PreOrder {
  number: string
  name: string
  price: number // cents
  redirect_url: string
  external: string
}

export interface Order {
  id: number
  uid: string
  app_id: string
  pre_order: PreOrder
  expires_in: number
  qr_data: string
  qr_image_url: string
  sched_agent_uid: string
  sched_pay_type: PayType
  sched_price: number // cents
  pay_record_uid?: string
  status: OrderStatus
  create_at: string
  update_at: string
}

export interface OrderCreateInput {
  app_id: string
  pre_order: PreOrder
  expires_in?: number
}

export interface OrderListParams {
  page?: number
  limit?: number
  status?: OrderStatus
  app_id?: string
  agent_uid?: string
}

export interface OrderListResponse {
  orders: Order[]
  total: number
  page: number
  limit: number
}
