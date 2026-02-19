import { NextRequest, NextResponse } from "next/server"
import { serverError, notFound } from "@/lib/api/auth"
import { OrderService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/order/[uid] - Get order
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params

    const order = await OrderService.getOrder(uid)
    if (!order) {
      return notFound("Order not found")
    }

    return NextResponse.json(order)
  } catch (err) {
    console.error("Get order error:", err)
    return serverError()
  }
}
