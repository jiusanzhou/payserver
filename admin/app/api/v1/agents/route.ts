import { NextResponse } from "next/server"
import { createServerSupabaseClient } from "@/lib/db/supabase"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import type { Database } from "@/types/database"

export const dynamic = 'force-dynamic'

type AgentInsert = Database["public"]["Tables"]["agents"]["Insert"]

export async function GET(request: Request) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get("page") || "1")
    const limit = parseInt(searchParams.get("limit") || "20")
    const status = searchParams.get("status")

    const supabase = await createServerSupabaseClient()

    let query = supabase
      .from("agents")
      .select("*", { count: "exact" })
      .is("deleted_at", null)
      .order("create_at", { ascending: false })
      .range((page - 1) * limit, page * limit - 1)

    if (status) {
      const statusMap: Record<string, number> = {
        online: 1,
        offline: 0,
      }
      query = query.eq("status", statusMap[status])
    }

    const { data, error, count } = await query

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({
      agents: data,
      total: count,
      page,
      limit,
    })
  } catch {
    return serverError()
  }
}

export async function POST(request: Request) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const body = await request.json()
    const { device_id, pay_types, ticket, device_info, external } = body

    if (!device_id) {
      return badRequest("device_id is required")
    }

    const supabase = await createServerSupabaseClient()

    const insertData: AgentInsert = {
      device_id,
      pay_types: pay_types || "",
      ticket: ticket || "",
      device_info: device_info || "",
      external: external || "",
      status: 0,
      heartbeat_at: new Date().toISOString(),
    }

    const { data, error } = await supabase
      .from("agents")
      .insert(insertData as never)
      .select()
      .single()

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json(data, { status: 201 })
  } catch {
    return serverError()
  }
}
