import { NextResponse } from "next/server"
import { createServerSupabaseClient } from "@/lib/db/supabase"
import { requireAuth, serverError } from "@/lib/api/auth"

export const dynamic = 'force-dynamic'

const STATUS_LABELS: Record<number, string> = {
  1: "待支付",
  2: "已支付",
  3: "已过期",
  4: "已取消",
}

export async function GET() {
  const auth = await requireAuth()
  if (!auth.authenticated) return auth.response

  try {
    const supabase = await createServerSupabaseClient()

    // Get date range for last 7 days
    const today = new Date()
    const sevenDaysAgo = new Date(today)
    sevenDaysAgo.setDate(today.getDate() - 6)
    sevenDaysAgo.setHours(0, 0, 0, 0)

    // Fetch orders from last 7 days
    const { data: orders, error } = await supabase
      .from("orders")
      .select("sched_price, status, create_at")
      .gte("create_at", sevenDaysAgo.toISOString())
      .order("create_at", { ascending: true })

    if (error) throw error

    type OrderRow = { sched_price: number; status: number; create_at: string }
    const orderList = (orders || []) as OrderRow[]

    // Initialize date map for last 7 days
    const dateMap = new Map<string, { revenue: number; orders: number; paid: number }>()
    for (let i = 0; i < 7; i++) {
      const d = new Date(sevenDaysAgo)
      d.setDate(sevenDaysAgo.getDate() + i)
      const key = `${d.getMonth() + 1}/${d.getDate()}`
      dateMap.set(key, { revenue: 0, orders: 0, paid: 0 })
    }

    // Status count map
    const statusMap = new Map<number, number>()

    // Process orders
    for (const order of orderList) {
      const date = new Date(order.create_at)
      const dateKey = `${date.getMonth() + 1}/${date.getDate()}`
      
      const entry = dateMap.get(dateKey)
      if (entry) {
        entry.orders++
        if (order.status === 2) {
          entry.paid++
          entry.revenue += order.sched_price || 0
        }
      }

      statusMap.set(order.status, (statusMap.get(order.status) || 0) + 1)
    }

    // Convert to arrays
    const revenueTrend = Array.from(dateMap.entries()).map(([date, data]) => ({
      date,
      revenue: data.revenue,
    }))

    const orderTrend = Array.from(dateMap.entries()).map(([date, data]) => ({
      date,
      orders: data.orders,
      paid: data.paid,
    }))

    const orderStats = Array.from(statusMap.entries()).map(([status, count]) => ({
      status: STATUS_LABELS[status] || `状态${status}`,
      count,
    }))

    return NextResponse.json({
      revenue_trend: revenueTrend,
      order_stats: orderStats,
      order_trend: orderTrend,
    })
  } catch {
    return serverError()
  }
}
