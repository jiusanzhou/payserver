import { NextRequest, NextResponse } from "next/server"
import { serverError } from "@/lib/api/auth"
import { RecordService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/agent/[uid]/records - List records by agent
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params
    const { searchParams } = new URL(request.url)
    const offset = parseInt(searchParams.get("offset") || "0")
    const limit = Math.min(parseInt(searchParams.get("limit") || "10"), 50)

    const { records, total } = await RecordService.listRecords(offset, limit, {
      agentUid: uid,
    })
    
    return NextResponse.json({ records, total })
  } catch (err) {
    console.error("List records by agent error:", err)
    return serverError()
  }
}
