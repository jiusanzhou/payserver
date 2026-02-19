import { NextRequest, NextResponse } from "next/server"
import { serverError } from "@/lib/api/auth"
import { AppService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/agent/[uid]/apps - List apps by agent
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  try {
    const { uid } = await params
    const { searchParams } = new URL(request.url)
    const offset = parseInt(searchParams.get("offset") || "0")
    const limit = Math.min(parseInt(searchParams.get("limit") || "10"), 50)

    const apps = await AppService.listAppsByAgent(uid, offset, limit)
    return NextResponse.json({ apps })
  } catch (err) {
    console.error("List apps by agent error:", err)
    return serverError()
  }
}
