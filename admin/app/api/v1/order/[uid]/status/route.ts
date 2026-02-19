import { NextRequest, NextResponse } from "next/server"
import { serverError } from "@/lib/api/auth"
import { OrderService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/order/[uid]/status - Get order status
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params
    const status = await OrderService.getOrderStatus(uid)
    return NextResponse.json({ status })
  } catch (err) {
    if (err instanceof Error && "code" in err) {
      return NextResponse.json(
        { error: err.message },
        { status: (err as { code: number }).code }
      )
    }
    console.error("Get order status error:", err)
    return serverError()
  }
}
