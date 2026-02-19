export type AgentStatus = "normal" | "offline" | "disable" | "pendding" | "busy" | "unknown"

export const AgentStatusMap: Record<number, AgentStatus> = {
  1: "normal",
  2: "offline",
  3: "disable",
  4: "pendding",
  5: "busy",
  6: "unknown",
}

export const AgentStatusLabel: Record<AgentStatus, string> = {
  normal: "正常",
  offline: "离线",
  disable: "已禁用",
  pendding: "等待中",
  busy: "忙碌",
  unknown: "未知",
}

export const AgentStatusColor: Record<AgentStatus, string> = {
  normal: "bg-green-100 text-green-800",
  offline: "bg-gray-100 text-gray-800",
  disable: "bg-red-100 text-red-800",
  pendding: "bg-yellow-100 text-yellow-800",
  busy: "bg-blue-100 text-blue-800",
  unknown: "bg-gray-100 text-gray-600",
}

export interface Agent {
  id: number
  uid: string
  device_id: string
  pay_types: string // JSON array: ["wechat", "alipay"]
  heartbeat_at: string
  status: AgentStatus
  ticket: string
  device_info: string // JSON object
  external: string // JSON object
  create_at: string
  update_at: string
}

export interface AgentCreateInput {
  device_id: string
  pay_types: string[]
  ticket?: string
}

export interface AgentUpdateInput {
  pay_types?: string[]
  status?: AgentStatus
  device_info?: Record<string, unknown>
}

export interface AgentListParams {
  page?: number
  limit?: number
  status?: AgentStatus
}

export interface AgentListResponse {
  agents: Agent[]
  total: number
  page: number
  limit: number
}
