import { NextRequest, NextResponse } from "next/server"
import { serverError, notFound } from "@/lib/api/auth"
import { RecordService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/order/[uid]/callback - Get callback status
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params
    const callback = await RecordService.getCallbackByOrder(uid)
    
    if (!callback) {
      return notFound("Callback not found")
    }

    return NextResponse.json(callback)
  } catch (err) {
    console.error("Get callback error:", err)
    return serverError()
  }
}
