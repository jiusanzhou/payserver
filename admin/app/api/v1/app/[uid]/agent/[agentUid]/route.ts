import { NextRequest, NextResponse } from "next/server"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import { AppService } from "@/lib/server"

export const dynamic = "force-dynamic"

// POST /api/v1/app/[uid]/agent/[agentUid] - Update agent weight
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

    await AppService.updateAgentWeight(uid, agentUid, weight)

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error("Update agent weight error:", err)
    return serverError()
  }
}

// DELETE /api/v1/app/[uid]/agent/[agentUid] - Remove agent from app
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string; agentUid: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { uid, agentUid } = await params
    await AppService.unbindAgentFromApp(uid, agentUid)

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error("Unbind agent error:", err)
    return serverError()
  }
}
