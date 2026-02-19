import { NextResponse } from "next/server"
import { createServerSupabaseClient } from "@/lib/db/supabase"
import { requireAuth, serverError } from "@/lib/api/auth"

export const dynamic = 'force-dynamic'

export async function GET(request: Request) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get("page") || "1")
    const limit = parseInt(searchParams.get("limit") || "20")
    const status = searchParams.get("status")
    const appId = searchParams.get("app_id")

    const supabase = await createServerSupabaseClient()

    let query = supabase
      .from("orders")
      .select("*", { count: "exact" })
      .order("create_at", { ascending: false })
      .range((page - 1) * limit, page * limit - 1)

    if (status) {
      const statusMap: Record<string, number> = {
        pending: 1,
        paid: 2,
        expired: 3,
        canceled: 4,
      }
      query = query.eq("status", statusMap[status])
    }

    if (appId) {
      query = query.eq("app_id", appId)
    }

    const { data, error, count } = await query

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({
      orders: data,
      total: count,
      page,
      limit,
    })
  } catch {
    return serverError()
  }
}
