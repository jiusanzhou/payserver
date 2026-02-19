import { NextRequest, NextResponse } from "next/server"
import { createServerSupabaseClient } from "@/lib/db/supabase"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import type { Database } from "@/types/database"

export const dynamic = "force-dynamic"

type AgentInsert = Database["public"]["Tables"]["agents"]["Insert"]

function generateUUID(): string {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0
    const v = c === "x" ? r : (r & 0x3) | 0x8
    return v.toString(16)
  })
}

export async function POST(request: NextRequest) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const body = await request.json()
    const deviceId = body.device_id

    if (!deviceId) {
      return badRequest("device_id is required")
    }

    const supabase = await createServerSupabaseClient()

    // Generate ticket
    const ticket = generateUUID()

    // Create pending agent
    const insertData: AgentInsert = {
      device_id: deviceId,
      ticket,
      status: 0, // pending
      pay_types: "",
      heartbeat_at: new Date().toISOString(),
      device_info: "",
      external: "",
    }

    const { error } = await supabase.from("agents").insert(insertData as never)

    if (error) {
      console.error("Failed to create pending agent:", error)
      return serverError("Failed to generate QR code")
    }

    // Return ticket info for QR code
    return NextResponse.json({
      name: process.env.PAYSERVER_NAME || "PayServer",
      host: process.env.PAYSERVER_API_URL || "",
      version: "1.0.0",
      ticket,
    })
  } catch {
    return serverError()
  }
}
