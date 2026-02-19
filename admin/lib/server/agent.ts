/**
 * PayServer Agent Service
 * Mirrors Go server/server_agent.go
 */

import { createServerSupabaseClient } from "@/lib/db/supabase"
import { getServerConfig } from "./config"
import { Errors } from "./errors"
import { AgentStatus, type Agent, type RegisterAgentTicket } from "./types"
import { generateUUID } from "./utils"

export async function prepareAgent(deviceId: string): Promise<RegisterAgentTicket> {
  const supabase = await createServerSupabaseClient()
  const config = getServerConfig()
  
  // Check pending agent limit
  const { count } = await supabase
    .from("agents")
    .select("*", { count: "exact", head: true })
    .eq("status", AgentStatus.Pending)
  
  if ((count || 0) >= config.maxPendingAgent) {
    throw Errors.LimitPendingAgent
  }
  
  const ticket = generateUUID()
  const uid = generateUUID()
  const now = new Date().toISOString()
  
  const { error } = await supabase.from("agents").insert({
    uid,
    device_id: deviceId,
    ticket,
    status: AgentStatus.Pending,
    pay_types: "",
    heartbeat_at: now,
    device_info: "",
    external: "",
    create_at: now,
    update_at: now,
  } as never)
  
  if (error) throw error
  
  return {
    name: config.name,
    host: config.host,
    version: config.version,
    ticket,
  }
}

export async function registerAgent(
  ticket: string,
  deviceId: string,
  payTypes: string,
  deviceInfo?: string,
  external?: string
): Promise<Agent> {
  const supabase = await createServerSupabaseClient()
  
  // Find pending agent with ticket
  const { data: pending, error: findError } = await supabase
    .from("agents")
    .select("*")
    .eq("ticket", ticket)
    .single()
  
  if (findError || !pending) throw Errors.InvalidTicket
  
  const pendingAgent = pending as unknown as Agent
  if (pendingAgent.status !== AgentStatus.Pending) throw Errors.InvalidTicket
  
  const now = new Date().toISOString()
  
  const { data, error } = await supabase
    .from("agents")
    .update({
      device_id: deviceId,
      device_info: deviceInfo || "",
      pay_types: payTypes,
      external: external || "",
      status: AgentStatus.Normal,
      heartbeat_at: now,
      update_at: now,
    } as never)
    .eq("uid", pendingAgent.uid)
    .select()
    .single()
  
  if (error) throw error
  return data as unknown as Agent
}

export async function getAgent(uid: string): Promise<Agent | null> {
  const supabase = await createServerSupabaseClient()
  
  const { data, error } = await supabase
    .from("agents")
    .select("*")
    .eq("uid", uid)
    .is("deleted_at", null)
    .single()
  
  if (error) return null
  return data as unknown as Agent
}

export async function getAgentByTicket(ticket: string): Promise<Agent | null> {
  const supabase = await createServerSupabaseClient()
  
  const { data, error } = await supabase
    .from("agents")
    .select("*")
    .eq("ticket", ticket)
    .single()
  
  if (error) return null
  return data as unknown as Agent
}

export async function updateAgent(
  uid: string,
  updates: Partial<Agent>
): Promise<Agent> {
  const supabase = await createServerSupabaseClient()
  
  const updateData = {
    ...updates,
    update_at: new Date().toISOString(),
  }
  
  // Remove fields that shouldn't be updated
  delete (updateData as Record<string, unknown>).uid
  delete (updateData as Record<string, unknown>).id
  delete (updateData as Record<string, unknown>).create_at
  delete (updateData as Record<string, unknown>).ticket
  
  const { data, error } = await supabase
    .from("agents")
    .update(updateData as never)
    .eq("uid", uid)
    .select()
    .single()
  
  if (error) throw error
  return data as unknown as Agent
}

export async function deleteAgent(uid: string): Promise<void> {
  const supabase = await createServerSupabaseClient()
  
  const { error } = await supabase
    .from("agents")
    .update({ deleted_at: new Date().toISOString() } as never)
    .eq("uid", uid)
  
  if (error) throw error
}

export async function listAgents(
  offset: number,
  limit: number,
  filters?: { status?: number }
): Promise<{ agents: Agent[]; total: number }> {
  const supabase = await createServerSupabaseClient()
  
  let query = supabase
    .from("agents")
    .select("*", { count: "exact" })
    .is("deleted_at", null)
    .order("create_at", { ascending: false })
    .range(offset, offset + limit - 1)
  
  if (filters?.status !== undefined) {
    query = query.eq("status", filters.status)
  }
  
  const { data, count, error } = await query
  
  if (error) throw error
  return { agents: (data || []) as unknown as Agent[], total: count || 0 }
}

export async function heartbeatAgent(uid: string): Promise<void> {
  const supabase = await createServerSupabaseClient()
  
  const { error } = await supabase
    .from("agents")
    .update({ heartbeat_at: new Date().toISOString() } as never)
    .eq("uid", uid)
  
  if (error) throw error
}
