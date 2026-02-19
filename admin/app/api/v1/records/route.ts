import { NextRequest, NextResponse } from "next/server"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import { RecordService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/records - List records
export async function GET(request: NextRequest) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const offset = parseInt(searchParams.get("offset") || "0")
    const limit = Math.min(parseInt(searchParams.get("limit") || "20"), 50)
    const type = searchParams.get("type")
    const agent_uid = searchParams.get("agent_uid")

    const filters: { type?: string; agentUid?: string } = {}
    if (type) filters.type = type
    if (agent_uid) filters.agentUid = agent_uid

    const { records, total } = await RecordService.listRecords(offset, limit, filters)

    return NextResponse.json({ records, total, offset, limit })
  } catch (err) {
    console.error("List records error:", err)
    return serverError()
  }
}

// POST /api/v1/records - Create record (from Agent app)
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { agent_uid, type, number, amount, timestamp, account_uid, external } = body

    if (!agent_uid || !type || !number || amount === undefined) {
      return badRequest("agent_uid, type, number, amount are required")
    }

    const record = await RecordService.createRecord({
      agent_uid,
      type,
      number,
      amount,
      timestamp: timestamp || new Date().toISOString(),
      account_uid: account_uid || "",
      external: external || "",
    })

    return NextResponse.json(record, { status: 201 })
  } catch (err) {
    if (err instanceof Error && "code" in err) {
      return NextResponse.json(
        { error: err.message },
        { status: (err as { code: number }).code }
      )
    }
    console.error("Create record error:", err)
    return serverError()
  }
}
