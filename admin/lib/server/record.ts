/**
 * PayServer Record Service
 * Mirrors Go server/server_record.go
 */

import { createServerSupabaseClient } from "@/lib/db/supabase"
import { Errors } from "./errors"
import { CallbackStatus, type PayRecord, type CallbackLog, type Order } from "./types"
import { generateUUID } from "./utils"
import { calculateNextRetry, MaxRetryAttempts } from "./types"
import { matchOrderByRecord } from "./order"
import { getApp } from "./app"

export async function createRecord(record: Partial<PayRecord>): Promise<PayRecord> {
  const supabase = await createServerSupabaseClient()
  
  const uid = generateUUID()
  const now = new Date().toISOString()
  
  const { data, error } = await supabase
    .from("pay_records")
    .insert({
      uid,
      agent_uid: record.agent_uid || "",
      type: record.type || "",
      number: record.number || "",
      amount: record.amount || 0,
      timestamp: record.timestamp || now,
      account_uid: record.account_uid || null,
      external: record.external || "",
      create_at: now,
      update_at: now,
    } as never)
    .select()
    .single()
  
  if (error) throw error
  
  const savedRecord = data as unknown as PayRecord
  
  // Try to match with pending order
  const order = await matchOrderByRecord(
    savedRecord.agent_uid,
    savedRecord.type,
    savedRecord.amount
  )
  
  // If matched, create callback entry
  if (order) {
    createCallback(order, savedRecord).catch(console.error)
  }
  
  return savedRecord
}

export async function getRecord(uid: string): Promise<PayRecord | null> {
  const supabase = await createServerSupabaseClient()
  
  const { data, error } = await supabase
    .from("pay_records")
    .select("*")
    .eq("uid", uid)
    .single()
  
  if (error) return null
  return data as unknown as PayRecord
}

export async function listRecords(
  offset: number,
  limit: number,
  filters?: { type?: string; agentUid?: string; appId?: string }
): Promise<{ records: PayRecord[]; total: number }> {
  const supabase = await createServerSupabaseClient()
  
  let query = supabase
    .from("pay_records")
    .select("*", { count: "exact" })
    .is("deleted_at", null)
    .order("create_at", { ascending: false })
    .range(offset, offset + limit - 1)
  
  if (filters?.type) {
    query = query.eq("type", filters.type)
  }
  if (filters?.agentUid) {
    query = query.eq("agent_uid", filters.agentUid)
  }
  
  const { data, count, error } = await query
  
  if (error) throw error
  return { records: (data || []) as unknown as PayRecord[], total: count || 0 }
}

// Callback methods

async function createCallback(order: Order, record: PayRecord): Promise<void> {
  const app = await getApp(order.app_id)
  if (!app || !app.callback_url) return
  
  const supabase = await createServerSupabaseClient()
  
  const payload = JSON.stringify({
    order_id: order.uid,
    number: order.pre_order?.number || "",
    status: "paid",
    amount: order.sched_price,
    pay_type: order.sched_pay_type,
    record_id: record.uid,
    timestamp: new Date().toISOString(),
  })
  
  const uid = generateUUID()
  const now = new Date().toISOString()
  
  await supabase.from("callback_logs").insert({
    uid,
    order_uid: order.uid,
    app_id: app.uid,
    callback_url: app.callback_url,
    payload,
    status: CallbackStatus.Pending,
    attempts: 0,
    max_attempts: MaxRetryAttempts,
    last_error: "",
    last_response: "",
    next_attempt: now,
    create_at: now,
    update_at: now,
  } as never)
}

export async function getCallbackByOrder(orderUid: string): Promise<CallbackLog | null> {
  const supabase = await createServerSupabaseClient()
  
  const { data, error } = await supabase
    .from("callback_logs")
    .select("*")
    .eq("order_uid", orderUid)
    .order("create_at", { ascending: false })
    .limit(1)
    .single()
  
  if (error) return null
  return data as unknown as CallbackLog
}

export async function retryCallback(orderUid: string): Promise<CallbackLog> {
  const callback = await getCallbackByOrder(orderUid)
  if (!callback) throw Errors.CallbackNotFound
  
  const supabase = await createServerSupabaseClient()
  const now = new Date().toISOString()
  
  const { data, error } = await supabase
    .from("callback_logs")
    .update({
      status: CallbackStatus.Pending,
      next_attempt: now,
      update_at: now,
    } as never)
    .eq("uid", callback.uid)
    .select()
    .single()
  
  if (error) throw error
  return data as unknown as CallbackLog
}

export async function listPendingCallbacks(limit: number): Promise<CallbackLog[]> {
  const supabase = await createServerSupabaseClient()
  const now = new Date().toISOString()
  
  const { data, error } = await supabase
    .from("callback_logs")
    .select("*")
    .eq("status", CallbackStatus.Pending)
    .lte("next_attempt", now)
    .order("next_attempt", { ascending: true })
    .limit(limit)
  
  if (error) throw error
  return (data || []) as unknown as CallbackLog[]
}

export async function processCallback(callback: CallbackLog): Promise<void> {
  const supabase = await createServerSupabaseClient()
  const now = new Date()
  
  callback.attempts++
  callback.last_attempt = now.toISOString()
  
  try {
    const response = await fetch(callback.callback_url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: callback.payload,
    })
    
    const body = await response.text()
    callback.last_response = body.slice(0, 1000)
    
    if (response.ok) {
      callback.status = CallbackStatus.Success
      callback.next_attempt = null
    } else {
      callback.last_error = response.statusText
      
      if (callback.attempts >= callback.max_attempts) {
        callback.status = CallbackStatus.Failed
        callback.next_attempt = null
      } else {
        const nextRetry = calculateNextRetry(callback.attempts)
        callback.next_attempt = nextRetry?.toISOString() || null
      }
    }
  } catch (err) {
    callback.last_error = err instanceof Error ? err.message : "Unknown error"
    
    if (callback.attempts >= callback.max_attempts) {
      callback.status = CallbackStatus.Failed
      callback.next_attempt = null
    } else {
      const nextRetry = calculateNextRetry(callback.attempts)
      callback.next_attempt = nextRetry?.toISOString() || null
    }
  }
  
  await supabase
    .from("callback_logs")
    .update({
      status: callback.status,
      attempts: callback.attempts,
      last_error: callback.last_error,
      last_response: callback.last_response,
      last_attempt: callback.last_attempt,
      next_attempt: callback.next_attempt,
      update_at: now.toISOString(),
    } as never)
    .eq("uid", callback.uid)
}
