import { NextRequest, NextResponse } from "next/server"
import { createServerSupabaseClient } from "@/lib/db/supabase"
import { requireAuth, notFound, serverError } from "@/lib/api/auth"

export const dynamic = "force-dynamic"

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ ticket: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { ticket } = await params
    const supabase = await createServerSupabaseClient()

    type AgentRow = { uid: string; status: number; device_id: string }

    const { data, error } = await supabase
      .from("agents")
      .select("uid, status, device_id")
      .eq("ticket", ticket)
      .single()

    if (error || !data) {
      return notFound("Ticket not found")
    }

    const agent = data as AgentRow

    // Status 0 = pending, 1 = normal (registered)
    const registered = agent.status === 1

    return NextResponse.json({
      registered,
      agent_uid: registered ? agent.uid : null,
    })
  } catch {
    return serverError()
  }
}
