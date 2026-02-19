import { NextRequest, NextResponse } from "next/server"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import { OrderService } from "@/lib/server"

export const dynamic = "force-dynamic"

// POST /api/v1/order - Create order
export async function POST(request: NextRequest) {
  // This endpoint may be called by external apps, so auth is via appid/secret
  try {
    const { searchParams } = new URL(request.url)
    const appId = searchParams.get("appid")
    const method = searchParams.get("method") || ""

    if (!appId) {
      return badRequest("appid is required")
    }

    const body = await request.json()
    const { number, name, price, redirect_url, external } = body

    if (!number) {
      return badRequest("order number is required")
    }
    if (!price || price <= 0) {
      return badRequest("price must be greater than 0")
    }

    const order = await OrderService.createOrder(appId, method, {
      number,
      name: name || "",
      price,
      redirect_url: redirect_url || "",
      external: external || "",
    })

    return NextResponse.json(order)
  } catch (err) {
    if (err instanceof Error && "code" in err) {
      return NextResponse.json(
        { error: err.message },
        { status: (err as { code: number }).code }
      )
    }
    console.error("Create order error:", err)
    return serverError()
  }
}
