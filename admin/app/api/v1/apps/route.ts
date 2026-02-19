import { NextResponse } from "next/server"
import { createServerSupabaseClient } from "@/lib/db/supabase"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import type { Database } from "@/types/database"

export const dynamic = 'force-dynamic'

type AppInsert = Database["public"]["Tables"]["apps"]["Insert"]

export async function GET(request: Request) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const page = parseInt(searchParams.get("page") || "1")
    const limit = parseInt(searchParams.get("limit") || "20")

    const supabase = await createServerSupabaseClient()

    const { data, error, count } = await supabase
      .from("apps")
      .select("*", { count: "exact" })
      .is("deleted_at", null)
      .order("create_at", { ascending: false })
      .range((page - 1) * limit, page * limit - 1)

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 })
    }

    return NextResponse.json({
      apps: data,
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
    const {
      name,
      description,
      callback_url,
      price_floor,
      price_ceil,
      expire_in,
      max_pendding_order,
      user_uid,
    } = body

    if (!name) {
      return badRequest("name is required")
    }

    const supabase = await createServerSupabaseClient()

    const generateRandomKey = (length: number) => {
      const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
      return Array.from({ length }, () => chars[Math.floor(Math.random() * chars.length)]).join("")
    }

    const insertData: AppInsert = {
      name,
      description: description || "",
      callback_url: callback_url || "",
      secret: generateRandomKey(32),
      aes_key: generateRandomKey(16),
      price_floor: price_floor || 0,
      price_ceil: price_ceil || 100000,
      expire_in: expire_in || 300,
      max_pendding_order: max_pendding_order || 10,
      user_uid: user_uid || "",
    }

    const { data, error } = await supabase
      .from("apps")
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
