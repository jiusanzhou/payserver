import { NextRequest, NextResponse } from "next/server"
import { serverError } from "@/lib/api/auth"
import { OrderService } from "@/lib/server"

export const dynamic = "force-dynamic"

// POST /api/v1/order/[uid]/cancel - Cancel order
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params
    const order = await OrderService.cancelOrder(uid)
    return NextResponse.json(order)
  } catch (err) {
    if (err instanceof Error && "code" in err) {
      return NextResponse.json(
        { error: err.message },
        { status: (err as { code: number }).code }
      )
    }
    console.error("Cancel order error:", err)
    return serverError()
  }
}
