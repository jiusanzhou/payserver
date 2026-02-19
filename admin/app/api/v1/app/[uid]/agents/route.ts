import { NextRequest, NextResponse } from "next/server"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import { AppService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/app/[uid]/agents - List agents bound to app
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  // TODO: re-enable auth for production
  // const auth = await requireAuth()
  // if (!auth.authenticated) return auth.response

  try {
    const { uid } = await params
    const { searchParams } = new URL(request.url)
    const offset = parseInt(searchParams.get("offset") || "0")
    const limit = Math.min(parseInt(searchParams.get("limit") || "20"), 50)

    const { bindings, agents } = await AppService.listAgentsByApp(uid, offset, limit)

    // Merge agent info into bindings
    const agentMap = new Map(agents.map((a) => [a.uid, a]))
    const result = bindings.map((b) => ({
      ...b,
      agent: agentMap.get(b.agent_uid) || null,
    }))

    return NextResponse.json({ bindings: result })
  } catch (err) {
    console.error("List agents by app error:", err)
    return serverError()
  }
}

// POST /api/v1/app/[uid]/agents - Add agent to app
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  // TODO: re-enable auth for production
  // const auth = await requireAuth()
  // if (!auth.authenticated) return auth.response

  try {
    const { uid } = await params
    const body = await request.json()
    const { agent_uid, weight = 1 } = body

    if (!agent_uid) {
      return badRequest("agent_uid is required")
    }

    await AppService.bindAgentToApp(uid, agent_uid, weight)

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error("Bind agent error:", err)
    return serverError()
  }
}
