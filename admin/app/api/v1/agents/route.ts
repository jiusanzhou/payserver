import { NextRequest, NextResponse } from "next/server"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import { AgentService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/agents - List agents
export async function GET(request: NextRequest) {
  // Skip auth check for now (can be re-enabled for admin-only access)
  // const auth = await requireAuth()
  // if (!auth.authenticated) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const offset = parseInt(searchParams.get("offset") || "0")
    const limit = Math.min(parseInt(searchParams.get("limit") || "20"), 50)
    const status = searchParams.get("status")

    const filters: { status?: number } = {}
    if (status) {
      const statusMap: Record<string, number> = { online: 1, offline: 2, pending: 4 }
      filters.status = statusMap[status]
    }

    const { agents, total } = await AgentService.listAgents(offset, limit, filters)

    return NextResponse.json({ agents, total, offset, limit })
  } catch (err) {
    console.error("List agents error:", err)
    return serverError()
  }
}

// POST /api/v1/agents - Register agent (with ticket)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { ticket, device_id, pay_types, device_info, external } = body

    if (!ticket) {
      return badRequest("ticket is required")
    }
    if (!device_id) {
      return badRequest("device_id is required")
    }
    if (!pay_types) {
      return badRequest("pay_types is required")
    }

    const agent = await AgentService.registerAgent(
      ticket,
      device_id,
      pay_types,
      device_info,
      external
    )

    return NextResponse.json(agent, { status: 201 })
  } catch (err) {
    if (err instanceof Error && "code" in err) {
      return NextResponse.json(
        { error: err.message },
        { status: (err as { code: number }).code }
      )
    }
    console.error("Register agent error:", err)
    return serverError()
  }
}
