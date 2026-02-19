import { NextRequest, NextResponse } from "next/server"
import { serverError } from "@/lib/api/auth"
import { AgentService } from "@/lib/server"

export const dynamic = "force-dynamic"

// POST /api/v1/agent/[uid]/heartbeat - Agent heartbeat
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params
    await AgentService.heartbeatAgent(uid)
    return NextResponse.json({ success: true })
  } catch (err) {
    console.error("Agent heartbeat error:", err)
    return serverError()
  }
}
