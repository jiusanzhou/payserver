import { NextRequest, NextResponse } from "next/server"
import { serverError } from "@/lib/api/auth"
import { RecordService } from "@/lib/server"

export const dynamic = "force-dynamic"

// POST /api/v1/order/[uid]/callback/retry - Retry callback
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params
    const callback = await RecordService.retryCallback(uid)
    return NextResponse.json(callback)
  } catch (err) {
    if (err instanceof Error && "code" in err) {
      return NextResponse.json(
        { error: err.message },
        { status: (err as { code: number }).code }
      )
    }
    console.error("Retry callback error:", err)
    return serverError()
  }
}
