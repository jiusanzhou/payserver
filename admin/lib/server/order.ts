/**
 * PayServer Order Service
 * Mirrors Go server/server_order.go
 */

import { createServerSupabaseClient } from "@/lib/db/supabase"
import { getServerConfig } from "./config"
import { Errors } from "./errors"
import {
  OrderStatus,
  AgentStatus,
  isSupportedPayType,
  PayType,
  type Order,
  type PreOrder,
  type App,
  type Agent,
} from "./types"
import { generateUUID, genPriceFloats, selectByWeight } from "./utils"

// In-memory unique IDs (in production, use Redis or DB)
const uniqueIDs = new Map<string, boolean>()

export async function createOrder(
  appId: string,
  method: string,
  preorder: PreOrder
): Promise<Order> {
  if (!method) method = PayType.WeChat
  
  if (!isSupportedPayType(method)) {
    throw Errors.UnsupportedPayMethod
  }
  
  const supabase = await createServerSupabaseClient()
  const config = getServerConfig()
  
  // Get app
  const { data: app, error: appError } = await supabase
    .from("apps")
    .select("*")
    .eq("uid", appId)
    .is("deleted_at", null)
    .single()
  
  if (appError || !app) {
    console.error("Get app error:", appError, "appId:", appId)
    throw Errors.AppNotFound
  }
  
  // Get agent bindings separately
  const { data: agentBindings } = await supabase
    .from("app_agents")
    .select("agent_uid, weight")
    .eq("app_uid", appId)
    .is("deleted_at", null)
  
  const appData = app as unknown as App
  const bindings = (agentBindings || []) as { agent_uid: string; weight: number }[]
  
  // Check pending order limit
  const { count: pendingCount } = await supabase
    .from("orders")
    .select("*", { count: "exact", head: true })
    .eq("app_id", appId)
    .eq("status", OrderStatus.Pending)
  
  const maxPending = appData.max_pendding_order || config.maxPendingOrder
  if ((pendingCount || 0) >= maxPending) {
    throw Errors.PendingOrderLimit
  }
  
  // Check order number uniqueness
  const { data: existingOrder } = await supabase
    .from("orders")
    .select("uid")
    .eq("app_id", appId)
    .eq("o_number", preorder.number)
    .single()
  
  if (existingOrder) throw Errors.OrderNumberExists
  
  // Get available agents
  if (bindings.length === 0) throw Errors.NoAvailableAgent
  
  const agentUids = bindings.map((b) => b.agent_uid)
  const { data: agents } = await supabase
    .from("agents")
    .select("*")
    .in("uid", agentUids)
    .eq("status", AgentStatus.Normal)
    .is("deleted_at", null)
  
  if (!agents || agents.length === 0) throw Errors.NoAvailableAgent
  
  const agentList = agents as unknown as Agent[]
  
  // Build weights array
  const weights = agentList.map((a) => {
    const binding = bindings.find((b) => b.agent_uid === a.uid)
    return binding?.weight || 1
  })
  
  // Weighted random selection
  const selectedAgent = selectByWeight(agentList, weights)
  if (!selectedAgent) throw Errors.NoAvailableAgent
  
  // Find available price slot
  const priceFloor = appData.price_floor || config.priceFloor
  const priceCeil = appData.price_ceil || config.priceCeil
  const priceFloats = genPriceFloats(priceFloor, priceCeil)
  
  let foundPrice: number | null = null
  let schedKey: string | null = null
  
  for (const delta of priceFloats) {
    const price = preorder.price + delta
    const key = `${selectedAgent.uid}-${method}-${price}`
    if (!uniqueIDs.has(key)) {
      foundPrice = price
      schedKey = key
      uniqueIDs.set(key, true)
      break
    }
  }
  
  if (foundPrice === null || !schedKey) {
    throw Errors.SchedPriceBusy
  }
  
  const expireIn = appData.expire_in || config.expireIn
  const uid = generateUUID()
  const now = new Date().toISOString()
  
  const { data: order, error: createError } = await supabase
    .from("orders")
    .insert({
      uid,
      app_id: appId,
      o_number: preorder.number,
      o_name: preorder.name,
      o_price: preorder.price,
      o_redirect_url: preorder.redirect_url,
      o_external: preorder.external,
      expires_in: expireIn,
      qr_data: "",
      qr_image_url: "",
      sched_agent_uid: selectedAgent.uid,
      sched_pay_type: method,
      sched_price: foundPrice,
      status: OrderStatus.Pending,
      create_at: now,
      update_at: now,
    } as never)
    .select()
    .single()
  
  if (createError) throw createError
  
  return order as unknown as Order
}

export async function getOrder(uid: string): Promise<Order | null> {
  const supabase = await createServerSupabaseClient()
  
  const { data, error } = await supabase
    .from("orders")
    .select("*")
    .eq("uid", uid)
    .single()
  
  if (error) return null
  return data as unknown as Order
}

export async function getOrderStatus(uid: string): Promise<number> {
  const order = await getOrder(uid)
  if (!order) throw Errors.OrderNotFound
  return order.status
}

export async function cancelOrder(uid: string): Promise<Order> {
  const supabase = await createServerSupabaseClient()
  
  const order = await getOrder(uid)
  if (!order) throw Errors.OrderNotFound
  
  if (order.status !== OrderStatus.Pending) {
    return order
  }
  
  // Release schedKey
  const schedKey = `${order.sched_agent_uid}-${order.sched_pay_type}-${order.sched_price}`
  uniqueIDs.delete(schedKey)
  
  const { data, error } = await supabase
    .from("orders")
    .update({ status: OrderStatus.Canceled, update_at: new Date().toISOString() } as never)
    .eq("uid", uid)
    .select()
    .single()
  
  if (error) throw error
  return data as unknown as Order
}

export async function listOrders(
  offset: number,
  limit: number,
  filters?: { appId?: string; status?: number }
): Promise<{ orders: Order[]; total: number }> {
  const supabase = await createServerSupabaseClient()
  
  let query = supabase
    .from("orders")
    .select("*", { count: "exact" })
    .is("deleted_at", null)
    .order("create_at", { ascending: false })
    .range(offset, offset + limit - 1)
  
  if (filters?.appId) {
    query = query.eq("app_id", filters.appId)
  }
  if (filters?.status) {
    query = query.eq("status", filters.status)
  }
  
  const { data, count, error } = await query
  
  if (error) throw error
  return { orders: (data || []) as unknown as Order[], total: count || 0 }
}

export async function matchOrderByRecord(
  agentUid: string,
  payType: string,
  amount: number
): Promise<Order | null> {
  const schedKey = `${agentUid}-${payType}-${amount}`
  
  const supabase = await createServerSupabaseClient()
  
  // Query DB directly instead of relying on in-memory cache
  const { data: orders } = await supabase
    .from("orders")
    .select("*")
    .eq("sched_agent_uid", agentUid)
    .eq("sched_pay_type", payType)
    .eq("sched_price", amount)
    .eq("status", OrderStatus.Pending)
    .limit(1)
  
  if (!orders || orders.length === 0) return null
  
  const order = orders[0] as unknown as Order
  
  // Release schedKey from cache if present
  uniqueIDs.delete(schedKey)
  
  // Update order status
  await supabase
    .from("orders")
    .update({ status: OrderStatus.Paid, update_at: new Date().toISOString() } as never)
    .eq("uid", order.uid)
  
  return order
}
