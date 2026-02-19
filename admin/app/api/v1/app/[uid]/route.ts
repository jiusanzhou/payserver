import { NextRequest, NextResponse } from "next/server"
import { requireAuth, serverError, notFound } from "@/lib/api/auth"
import { AppService } from "@/lib/server"

export const dynamic = "force-dynamic"

// GET /api/v1/app/[uid] - Get app
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { uid } = await params
    const app = await AppService.getApp(uid)

    if (!app) {
      return notFound("App not found")
    }

    return NextResponse.json(app)
  } catch (err) {
    console.error("Get app error:", err)
    return serverError()
  }
}

// POST /api/v1/app/[uid] - Update app
export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { uid } = await params
    const body = await request.json()

    const app = await AppService.updateApp(uid, body)

    return NextResponse.json(app)
  } catch (err) {
    if (err instanceof Error && "code" in err) {
      return NextResponse.json(
        { error: err.message },
        { status: (err as { code: number }).code }
      )
    }
    console.error("Update app error:", err)
    return serverError()
  }
}

// DELETE /api/v1/app/[uid] - Delete app
export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ uid: string }> }
) {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const { uid } = await params
    await AppService.deleteApp(uid)

    return NextResponse.json({ success: true })
  } catch (err) {
    console.error("Delete app error:", err)
    return serverError()
  }
}
