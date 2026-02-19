/**
 * Go Backend API Client
 * 用于从 Next.js 调用 Go 后端 API
 */

const BACKEND_URL = process.env.GO_BACKEND_URL || 'http://localhost:8080'

interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE'
  body?: unknown
  headers?: Record<string, string>
}

async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { method = 'GET', body, headers = {} } = options

  const response = await fetch(`${BACKEND_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: body ? JSON.stringify(body) : undefined,
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({}))
    throw new Error(error.message || `Request failed: ${response.status}`)
  }

  return response.json()
}

// ==================== Orders ====================

export interface Order {
  uid: string
  app_id: string
  pre_order: {
    number: string
    name: string
    price: number
    redirect_url: string
    external: string
  }
  expires_in: number
  qr_data: string
  qr_image_url: string
  sched_agent_uid: string
  sched_pay_type: string
  sched_price: number
  pay_record_uid: string
  status: number
  create_at: string
  updated_at: string
}

export async function getOrders(params?: {
  offset?: number
  limit?: number
  status?: number
  app_id?: string
}): Promise<{ data: Order[] }> {
  const searchParams = new URLSearchParams()
  if (params?.offset) searchParams.set('offset', String(params.offset))
  if (params?.limit) searchParams.set('limit', String(params.limit))
  const query = searchParams.toString()
  return request(`/api/v1/orders${query ? `?${query}` : ''}`)
}

export async function getOrder(uid: string): Promise<Order> {
  return request(`/api/v1/order/${uid}`)
}

export async function cancelOrder(uid: string): Promise<Order> {
  return request(`/api/v1/order/${uid}/cancel`, { method: 'POST' })
}

// ==================== Agents ====================

export interface Agent {
  uid: string
  device_id: string
  device_info: string
  pay_types: string
  status: number
  heartbeat_at: string
  external: string
  create_at: string
  updated_at: string
}

export async function getAgents(params?: {
  offset?: number
  limit?: number
}): Promise<{ data: Agent[] }> {
  const searchParams = new URLSearchParams()
  if (params?.offset) searchParams.set('offset', String(params.offset))
  if (params?.limit) searchParams.set('limit', String(params.limit))
  const query = searchParams.toString()
  return request(`/api/v1/agents${query ? `?${query}` : ''}`)
}

export async function getAgent(uid: string): Promise<Agent> {
  return request(`/api/v1/agent/${uid}`)
}

export async function deleteAgent(uid: string): Promise<void> {
  return request(`/api/v1/agent/${uid}`, { method: 'DELETE' })
}

// ==================== Apps ====================

export interface App {
  uid: string
  name: string
  description: string
  callback_url: string
  secret: string
  price_floor: number
  price_ceil: number
  expire_in: number
  max_pendding_order: number
  agents: Agent[]
  create_at: string
  updated_at: string
}

export async function getApps(params?: {
  offset?: number
  limit?: number
}): Promise<{ data: App[] }> {
  const searchParams = new URLSearchParams()
  if (params?.offset) searchParams.set('offset', String(params.offset))
  if (params?.limit) searchParams.set('limit', String(params.limit))
  const query = searchParams.toString()
  return request(`/api/v1/apps${query ? `?${query}` : ''}`)
}

export async function getApp(uid: string): Promise<App> {
  return request(`/api/v1/app/${uid}`)
}

export async function createApp(data: {
  name: string
  callback_url: string
  description?: string
  price_floor?: number
  price_ceil?: number
  expire_in?: number
  max_pendding_order?: number
}): Promise<App> {
  return request('/api/v1/apps', { method: 'POST', body: data })
}

export async function updateApp(uid: string, data: Partial<App>): Promise<App> {
  return request(`/api/v1/app/${uid}`, { method: 'POST', body: data })
}

export async function deleteApp(uid: string): Promise<void> {
  return request(`/api/v1/app/${uid}`, { method: 'DELETE' })
}

export async function bindAgentToApp(appUid: string, agentUid: string, weight = 1): Promise<void> {
  return request(`/api/v1/app/${appUid}/agents`, {
    method: 'POST',
    body: { agent_uid: agentUid, weight },
  })
}

export async function unbindAgentFromApp(appUid: string, agentUid: string): Promise<void> {
  return request(`/api/v1/app/${appUid}/agent/${agentUid}`, { method: 'DELETE' })
}

// ==================== Records ====================

export interface PayRecord {
  uid: string
  agent_uid: string
  type: string
  number: string
  amount: number
  timestamp: string
  external: string
  create_at: string
  updated_at: string
}

export async function getRecords(params?: {
  offset?: number
  limit?: number
  method?: string
}): Promise<{ data: PayRecord[] }> {
  const searchParams = new URLSearchParams()
  if (params?.offset) searchParams.set('offset', String(params.offset))
  if (params?.limit) searchParams.set('limit', String(params.limit))
  if (params?.method) searchParams.set('method', params.method)
  const query = searchParams.toString()
  return request(`/api/v1/records${query ? `?${query}` : ''}`)
}

export async function getRecord(uid: string): Promise<PayRecord> {
  return request(`/api/v1/record/${uid}`)
}
