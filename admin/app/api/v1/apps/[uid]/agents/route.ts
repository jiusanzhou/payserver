import { NextRequest, NextResponse } from "next/server"
import { createServerSupabaseClient } from "@/lib/db/supabase"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import type { Database } from "@/types/database"

export const dynamic = "force-dynamic"

type AppAgentInsert = Database["public"]["Tables"]["app_agents"]["Insert"]
type AppAgentRow = Database["public"]["Tables"]["app_agents"]["Row"]

// GET /api/v1/apps/[uid]/agents - List agents bound to app
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { uid } = await params
    const supabase = await createServerSupabaseClient()

    // Get bindings with agent info
    const { data: bindings, error } = await supabase
      .from("app_agents")
      .select("agent_uid, weight")
      .eq("app_uid", uid)
      .is("deleted_at", null)

    if (error) throw error

    const bindingsList = (bindings || []) as Pick<AppAgentRow, "agent_uid" | "weight">[]

    // Get agent details
    const agentUids = bindingsList.map((b) => b.agent_uid)
    let agents: Record<string, unknown>[] = []

    if (agentUids.length > 0) {
      const { data: agentData } = await supabase
        .from("agents")
        .select("uid, device_id, device_info, status, heartbeat_at")
        .in("uid", agentUids)

      agents = agentData || []
    }

    // Merge agent info into bindings
    const agentMap = new Map(agents.map((a) => [(a as { uid: string }).uid, a]))
    const result = bindingsList.map((b) => ({
      ...b,
      agent: agentMap.get(b.agent_uid) || null,
    }))

    return NextResponse.json({ bindings: result })
  } catch {
    return serverError()
  }
}

// POST /api/v1/apps/[uid]/agents - Add agent to app
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { uid } = await params
    const body = await request.json()
    const { agent_uid, weight = 1 } = body

    if (!agent_uid) {
      return badRequest("agent_uid is required")
    }

    const supabase = await createServerSupabaseClient()

    // Check if binding already exists
    const { data: existing } = await supabase
      .from("app_agents")
      .select("id")
      .eq("app_uid", uid)
      .eq("agent_uid", agent_uid)
      .is("deleted_at", null)
      .single()

    if (existing) {
      return badRequest("Agent already bound to this app")
    }

    const insertData: AppAgentInsert = {
      app_uid: uid,
      agent_uid,
      weight: Math.max(1, Math.min(100, weight)),
    }

    const { error } = await supabase
      .from("app_agents")
      .insert(insertData as never)

    if (error) throw error

    return NextResponse.json({ success: true })
  } catch {
    return serverError()
  }
}
