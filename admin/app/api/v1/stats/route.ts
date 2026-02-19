import { NextResponse } from "next/server"
import { createServerSupabaseClient } from "@/lib/db/supabase"
import { requireAuth, serverError } from "@/lib/api/auth"

export const dynamic = 'force-dynamic'

export async function GET() {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const supabase = await createServerSupabaseClient()

    const today = new Date()
    today.setHours(0, 0, 0, 0)

    const [ordersResult, agentsResult, appsResult, revenueResult] = await Promise.all([
      supabase
        .from("orders")
        .select("*", { count: "exact", head: true })
        .gte("create_at", today.toISOString()),
      supabase
        .from("agents")
        .select("*", { count: "exact", head: true })
        .eq("status", 1),
      supabase
        .from("apps")
        .select("*", { count: "exact", head: true }),
      supabase
        .from("orders")
        .select("sched_price")
        .eq("status", 2)
        .gte("create_at", today.toISOString()),
    ])

    const totalRevenue = (revenueResult.data as { sched_price: number }[] | null)?.reduce(
      (sum, order) => sum + (order.sched_price || 0),
      0
    ) || 0

    return NextResponse.json({
      today_orders: ordersResult.count || 0,
      online_agents: agentsResult.count || 0,
      active_apps: appsResult.count || 0,
      today_revenue: totalRevenue,
    })
  } catch {
    return serverError()
  }
}
