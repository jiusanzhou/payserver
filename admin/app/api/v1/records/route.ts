import { NextResponse } from "next/server"
import { createServerSupabaseClient } from "@/lib/db/supabase"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import type { Database } from "@/types/database"

export const dynamic = 'force-dynamic'

type RecordInsert = Database["public"]["Tables"]["pay_records"]["Insert"]

export async function GET(request: Request) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get("page") || "1")
    const limit = parseInt(searchParams.get("limit") || "20")
    const type = searchParams.get("type")
    const agent_uid = searchParams.get("agent_uid")

    const supabase = await createServerSupabaseClient()

    let query = supabase
      .from("pay_records")
      .select("*", { count: "exact" })
      .is("deleted_at", null)
      .order("create_at", { ascending: false })
      .range((page - 1) * limit, page * limit - 1)

    if (type) {
      query = query.eq("type", type)
    }

    if (agent_uid) {
      query = query.eq("agent_uid", agent_uid)
    }

    const { data, error, count } = await query

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({
      records: data,
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
    const { agent_uid, type, number, amount, timestamp, account_uid, external } = body

    if (!agent_uid || !type || !number || !amount) {
      return badRequest("agent_uid, type, number, amount are required")
    }

    const supabase = await createServerSupabaseClient()

    const insertData: RecordInsert = {
      agent_uid,
      type,
      number,
      amount,
      timestamp: timestamp || new Date().toISOString(),
      account_uid: account_uid || "",
      external: external || "",
    }

    const { data, error } = await supabase
      .from("pay_records")
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
