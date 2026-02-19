import { NextRequest, NextResponse } from "next/server"
import { requireAuth, serverError, notFound } from "@/lib/api/auth"
import { RecordService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/record/[uid] - Get record
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { uid } = await params
    const record = await RecordService.getRecord(uid)

    if (!record) {
      return notFound("Record not found")
    }

    return NextResponse.json(record)
  } catch (err) {
    console.error("Get record error:", err)
    return serverError()
  }
}
