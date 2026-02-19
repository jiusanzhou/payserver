import { NextRequest, NextResponse } from "next/server"
import { serverError, notFound } from "@/lib/api/auth"
import { AgentService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/agent/[uid] - Get agent
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params
    const agent = await AgentService.getAgent(uid)
    
    if (!agent) {
      return notFound("Agent not found")
    }

    return NextResponse.json(agent)
  } catch (err) {
    console.error("Get agent error:", err)
    return serverError()
  }
}

// POST /api/v1/agent/[uid] - Update agent
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params
    const body = await request.json()

    const agent = await AgentService.updateAgent(uid, body)
    return NextResponse.json(agent)
  } catch (err) {
    if (err instanceof Error && "code" in err) {
      return NextResponse.json(
        { error: err.message },
        { status: (err as { code: number }).code }
      )
    }
    console.error("Update agent error:", err)
    return serverError()
  }
}

// DELETE /api/v1/agent/[uid] - Delete agent
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params
    await AgentService.deleteAgent(uid)
    return NextResponse.json({ success: true })
  } catch (err) {
    console.error("Delete agent error:", err)
    return serverError()
  }
}
