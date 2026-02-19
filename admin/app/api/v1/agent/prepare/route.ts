import { NextRequest, NextResponse } from "next/server"
import { badRequest, serverError } from "@/lib/api/auth"
import { AgentService } from "@/lib/server"

export const dynamic = "force-dynamic"

// POST /api/v1/agent/prepare - Prepare agent (generate ticket)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { device_id } = body

    if (!device_id) {
      return badRequest("device_id is required")
    }

    const ticket = await AgentService.prepareAgent(device_id)
    return NextResponse.json(ticket)
  } catch (err) {
    if (err instanceof Error && "code" in err) {
      return NextResponse.json(
        { error: err.message },
        { status: (err as { code: number }).code }
      )
    }
    console.error("Prepare agent error:", err)
    return serverError()
  }
}
