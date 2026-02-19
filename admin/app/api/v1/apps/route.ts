import { NextRequest, NextResponse } from "next/server"
import { requireAuth, badRequest, serverError } from "@/lib/api/auth"
import { AppService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/apps - List apps
export async function GET(request: NextRequest) {
  // TODO: re-enable auth for production
  // const auth = await requireAuth()
  // if (!auth.authenticated) return auth.response

  try {
    const { searchParams } = new URL(request.url)
    const offset = parseInt(searchParams.get("offset") || "0")
    const limit = Math.min(parseInt(searchParams.get("limit") || "20"), 50)

    const { apps, total } = await AppService.listApps(offset, limit)

    return NextResponse.json({ apps, total, offset, limit })
  } catch (err) {
    console.error("List apps error:", err)
    return serverError()
  }
}

// POST /api/v1/apps - Create app
export async function POST(request: NextRequest) {
  // TODO: re-enable auth for production
  // const auth = await requireAuth()
  // if (!auth.authenticated) return auth.response

  try {
    const body = await request.json()
    const { name } = body

    if (!name) {
      return badRequest("name is required")
    }

    const app = await AppService.createApp(body)

    return NextResponse.json(app, { status: 201 })
  } catch (err) {
    if (err instanceof Error && "code" in err) {
      return NextResponse.json(
        { error: err.message },
        { status: (err as { code: number }).code }
      )
    }
    console.error("Create app error:", err)
    return serverError()
  }
}
