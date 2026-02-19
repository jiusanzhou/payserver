import type { Agent } from "./agent"

export interface App {
  id: number
  uid: string
  name: string
  description: string
  callback_url: string
  secret: string
  aes_key: string
  price_floor: number // cents, default 100 (1 yuan)
  price_ceil: number // cents, default 0 (no limit)
  expire_in: number // seconds
  max_pendding_order: number
  user_uid: string
  agents?: Agent[]
  create_at: string
  update_at: string
}

export interface AppCreateInput {
  name: string
  description?: string
  callback_url: string
  price_floor?: number
  price_ceil?: number
  expire_in?: number
  max_pendding_order?: number
}

export interface AppUpdateInput {
  name?: string
  description?: string
  callback_url?: string
  price_floor?: number
  price_ceil?: number
  expire_in?: number
  max_pendding_order?: number
}

export interface AppListParams {
  page?: number
  limit?: number
  user_uid?: string
}

export interface AppListResponse {
  apps: App[]
  total: number
  page: number
  limit: number
}

export interface AppAgentBind {
  app_uid: string
  agent_uid: string
  weight: number
}
