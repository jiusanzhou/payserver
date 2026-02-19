import { NextRequest, NextResponse } from "next/server"
import { createServerSupabaseClient } from "@/lib/db/supabase"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import type { Database } from "@/types/database"

export const dynamic = "force-dynamic"

type AppAgentUpdate = Database["public"]["Tables"]["app_agents"]["Update"]

// POST /api/v1/apps/[uid]/agents/[agentUid] - Update agent weight
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string; agentUid: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { uid, agentUid } = await params
    const body = await request.json()
    const { weight } = body

    if (weight === undefined) {
      return badRequest("weight is required")
    }

    const supabase = await createServerSupabaseClient()

    const updateData: AppAgentUpdate = {
      weight: Math.max(1, Math.min(100, weight)),
    }

    const { error } = await supabase
      .from("app_agents")
      .update(updateData as never)
      .eq("app_uid", uid)
      .eq("agent_uid", agentUid)
      .is("deleted_at", null)

    if (error) throw error

    return NextResponse.json({ success: true })
  } catch {
    return serverError()
  }
}

// DELETE /api/v1/apps/[uid]/agents/[agentUid] - Remove agent from app
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string; agentUid: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { uid, agentUid } = await params
    const supabase = await createServerSupabaseClient()

    const updateData: AppAgentUpdate = {
      deleted_at: new Date().toISOString(),
    }

    // Soft delete by setting deleted_at
    const { error } = await supabase
      .from("app_agents")
      .update(updateData as never)
      .eq("app_uid", uid)
      .eq("agent_uid", agentUid)
      .is("deleted_at", null)

    if (error) throw error

    return NextResponse.json({ success: true })
  } catch {
    return serverError()
  }
}
