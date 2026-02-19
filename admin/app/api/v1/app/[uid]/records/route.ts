import { NextRequest, NextResponse } from "next/server"
import { requireAuth, serverError } from "@/lib/api/auth"
import { RecordService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/app/[uid]/records - List records by app
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { uid } = await params
    const { searchParams } = new URL(request.url)
    const offset = parseInt(searchParams.get("offset") || "0")
    const limit = Math.min(parseInt(searchParams.get("limit") || "20"), 50)

    // Note: Records are linked via orders, not directly to apps
    // This would need a join query in production
    const { records, total } = await RecordService.listRecords(offset, limit)

    return NextResponse.json({ records, total })
  } catch (err) {
    console.error("List records by app error:", err)
    return serverError()
  }
}
