/**
 * PayServer App Service
 * Mirrors Go server/server_app.go
 */

import { createServerSupabaseClient } from "@/lib/db/supabase"
import { getServerConfig } from "./config"
import { Errors } from "./errors"
import { type App, type Agent, type AppAgentBind } from "./types"
import { generateUUID } from "./utils"

function ensureApp(app: Partial<App>): void {
  const config = getServerConfig()
  
  if (app.callback_url && !app.callback_url.startsWith("http")) {
    throw new Error("callback should be a url")
  }
  
  if (!app.expire_in || app.expire_in <= 0) {
    app.expire_in = config.expireIn
  }
  if (!app.price_ceil || app.price_ceil <= 0) {
    app.price_ceil = config.priceCeil
  }
  if (!app.price_floor || app.price_floor <= 0) {
    app.price_floor = config.priceFloor
  }
  if (!app.max_pendding_order || app.max_pendding_order <= 0) {
    app.max_pendding_order = config.maxPendingOrder
  }
}

export async function createApp(app: Partial<App>): Promise<App> {
  ensureApp(app)
  
  const supabase = await createServerSupabaseClient()
  const uid = generateUUID()
  const secret = generateUUID()
  const now = new Date().toISOString()
  
  const { data, error } = await supabase
    .from("apps")
    .insert({
      uid,
      name: app.name || "",
      description: app.description || "",
      callback_url: app.callback_url || "",
      secret,
      aes_key: "",
      price_floor: app.price_floor,
      price_ceil: app.price_ceil,
      expire_in: app.expire_in,
      max_pendding_order: app.max_pendding_order,
      user_uid: app.user_uid || null,
      create_at: now,
      update_at: now,
    } as never)
    .select()
    .single()
  
  if (error) throw error
  return data as unknown as App
}

export async function getApp(uid: string): Promise<App | null> {
  const supabase = await createServerSupabaseClient()
  
  const { data, error } = await supabase
    .from("apps")
    .select("*")
    .eq("uid", uid)
    .is("deleted_at", null)
    .single()
  
  if (error) return null
  return data as unknown as App
}

export async function getAppByName(name: string): Promise<App | null> {
  const supabase = await createServerSupabaseClient()
  
  const { data, error } = await supabase
    .from("apps")
    .select("*")
    .eq("name", name)
    .is("deleted_at", null)
    .single()
  
  if (error) return null
  return data as unknown as App
}

export async function updateApp(uid: string, updates: Partial<App>): Promise<App> {
  ensureApp(updates)
  
  const supabase = await createServerSupabaseClient()
  
  const updateData = {
    ...updates,
    update_at: new Date().toISOString(),
  }
  
  // Remove fields that shouldn't be updated
  delete (updateData as Record<string, unknown>).uid
  delete (updateData as Record<string, unknown>).id
  delete (updateData as Record<string, unknown>).create_at
  delete (updateData as Record<string, unknown>).secret
  
  const { data, error } = await supabase
    .from("apps")
    .update(updateData as never)
    .eq("uid", uid)
    .select()
    .single()
  
  if (error) throw error
  return data as unknown as App
}

export async function deleteApp(uid: string): Promise<void> {
  const supabase = await createServerSupabaseClient()
  
  const { error } = await supabase
    .from("apps")
    .update({ deleted_at: new Date().toISOString() } as never)
    .eq("uid", uid)
  
  if (error) throw error
}

export async function listApps(
  offset: number,
  limit: number
): Promise<{ apps: App[]; total: number }> {
  const supabase = await createServerSupabaseClient()
  
  const { data, count, error } = await supabase
    .from("apps")
    .select("*", { count: "exact" })
    .is("deleted_at", null)
    .order("create_at", { ascending: false })
    .range(offset, offset + limit - 1)
  
  if (error) throw error
  return { apps: (data || []) as unknown as App[], total: count || 0 }
}

// Agent binding methods

export async function bindAgentToApp(
  appUid: string,
  agentUid: string,
  weight: number = 1
): Promise<void> {
  const supabase = await createServerSupabaseClient()
  
  // Check if already bound
  const { data: existing } = await supabase
    .from("app_agents")
    .select("id")
    .eq("app_uid", appUid)
    .eq("agent_uid", agentUid)
    .is("deleted_at", null)
    .single()
  
  if (existing) return // Already bound
  
  const { error } = await supabase.from("app_agents").insert({
    app_uid: appUid,
    agent_uid: agentUid,
    weight: Math.max(1, Math.min(100, weight)),
  } as never)
  
  if (error) throw error
}

export async function unbindAgentFromApp(
  appUid: string,
  agentUid: string
): Promise<void> {
  const supabase = await createServerSupabaseClient()
  
  const { error } = await supabase
    .from("app_agents")
    .update({ deleted_at: new Date().toISOString() } as never)
    .eq("app_uid", appUid)
    .eq("agent_uid", agentUid)
    .is("deleted_at", null)
  
  if (error) throw error
}

export async function updateAgentWeight(
  appUid: string,
  agentUid: string,
  weight: number
): Promise<void> {
  const supabase = await createServerSupabaseClient()
  
  const { error } = await supabase
    .from("app_agents")
    .update({ weight: Math.max(1, Math.min(100, weight)) } as never)
    .eq("app_uid", appUid)
    .eq("agent_uid", agentUid)
    .is("deleted_at", null)
  
  if (error) throw error
}

export async function listAgentsByApp(
  appUid: string,
  offset: number,
  limit: number
): Promise<{ bindings: AppAgentBind[]; agents: Agent[] }> {
  const supabase = await createServerSupabaseClient()
  
  const { data: bindings, error } = await supabase
    .from("app_agents")
    .select("agent_uid, weight")
    .eq("app_uid", appUid)
    .is("deleted_at", null)
    .range(offset, offset + limit - 1)
  
  if (error) throw error
  
  const agentUids = (bindings || []).map((b) => (b as { agent_uid: string }).agent_uid)
  let agents: Agent[] = []
  
  if (agentUids.length > 0) {
    const { data: agentData } = await supabase
      .from("agents")
      .select("*")
      .in("uid", agentUids)
    
    agents = (agentData || []) as unknown as Agent[]
  }
  
  return {
    bindings: (bindings || []) as unknown as AppAgentBind[],
    agents,
  }
}

export async function listAppsByAgent(
  agentUid: string,
  offset: number,
  limit: number
): Promise<App[]> {
  const supabase = await createServerSupabaseClient()
  
  const { data: bindings } = await supabase
    .from("app_agents")
    .select("app_uid")
    .eq("agent_uid", agentUid)
    .is("deleted_at", null)
    .range(offset, offset + limit - 1)
  
  const appUids = (bindings || []).map((b) => (b as { app_uid: string }).app_uid)
  
  if (appUids.length === 0) return []
  
  const { data: apps } = await supabase
    .from("apps")
    .select("*")
    .in("uid", appUids)
    .is("deleted_at", null)
  
  return (apps || []) as unknown as App[]
}
