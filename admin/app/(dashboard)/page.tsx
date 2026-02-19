"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { formatPrice, formatDate } from "@/lib/utils"
import {
  ShoppingCart,
  Smartphone,
  AppWindow,
  TrendingUp,
} from "lucide-react"
import {
  RevenueChart,
  OrderStatsChart,
  OrderTrendChart,
} from "@/components/dashboard"

interface Stats {
  today_orders: number
  online_agents: number
  active_apps: number
  today_revenue: number
}

interface Order {
  uid: string
  pre_order?: { number: string }
  sched_price: number
  status: number
  create_at: string
}

interface ChartData {
  revenue_trend: { date: string; revenue: number }[]
  order_stats: { status: string; count: number }[]
  order_trend: { date: string; orders: number; paid: number }[]
}

const statusVariant: Record<number, "success" | "warning" | "secondary"> = {
  1: "warning",
  2: "success",
  3: "secondary",
}

const statusLabel: Record<number, string> = {
  1: "待支付",
  2: "已支付",
  3: "已过期",
  4: "已取消",
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats>({
    today_orders: 0,
    online_agents: 0,
    active_apps: 0,
    today_revenue: 0,
  })
  const [recentOrders, setRecentOrders] = useState<Order[]>([])
  const [chartData, setChartData] = useState<ChartData>({
    revenue_trend: [],
    order_stats: [],
    order_trend: [],
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsRes, ordersRes, chartsRes] = await Promise.all([
          fetch("/api/v1/stats"),
          fetch("/api/v1/orders?limit=5"),
          fetch("/api/v1/stats/charts"),
        ])
        const statsData = await statsRes.json()
        const ordersData = await ordersRes.json()
        const chartsData = await chartsRes.json()
        setStats(statsData)
        setRecentOrders(ordersData.orders || [])
        setChartData(chartsData)
      } catch (err) {
        console.error("Failed to fetch dashboard data:", err)
      } finally {
        setLoading(false)
      }
    }
    fetchData()
  }, [])

  const statCards = [
    {
      title: "今日订单",
      value: stats.today_orders.toString(),
      icon: ShoppingCart,
    },
    {
      title: "在线设备",
      value: stats.online_agents.toString(),
      icon: Smartphone,
    },
    {
      title: "活跃应用",
      value: stats.active_apps.toString(),
      icon: AppWindow,
    },
    {
      title: "今日收入",
      value: formatPrice(stats.today_revenue),
      icon: TrendingUp,
    },
  ]

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">概览</h1>
        <p className="text-muted-foreground">
          欢迎回来，这是您的 PayServer 数据概览
        </p>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {statCards.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {stat.title}
              </CardTitle>
              <stat.icon className="h-4 w-4 text-muted-foreground" />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">
                {loading ? "-" : stat.value}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Charts Row */}
      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle>收入趋势（近7天）</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="h-[300px] flex items-center justify-center text-muted-foreground">
                加载中...
              </div>
            ) : chartData.revenue_trend.length === 0 ? (
              <div className="h-[300px] flex items-center justify-center text-muted-foreground">
                暂无数据
              </div>
            ) : (
              <RevenueChart data={chartData.revenue_trend} />
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>订单状态分布</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="h-[300px] flex items-center justify-center text-muted-foreground">
                加载中...
              </div>
            ) : chartData.order_stats.length === 0 ? (
              <div className="h-[300px] flex items-center justify-center text-muted-foreground">
                暂无数据
              </div>
            ) : (
              <OrderStatsChart data={chartData.order_stats} />
            )}
          </CardContent>
        </Card>
      </div>

      {/* Order Trend */}
      <Card>
        <CardHeader>
          <CardTitle>订单趋势（近7天）</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="h-[300px] flex items-center justify-center text-muted-foreground">
              加载中...
            </div>
          ) : chartData.order_trend.length === 0 ? (
            <div className="h-[300px] flex items-center justify-center text-muted-foreground">
              暂无数据
            </div>
          ) : (
            <OrderTrendChart data={chartData.order_trend} />
          )}
        </CardContent>
      </Card>

      {/* Recent Orders */}
      <Card>
        <CardHeader>
          <CardTitle>最近订单</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8 text-muted-foreground">加载中...</div>
          ) : recentOrders.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">暂无订单</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>订单号</TableHead>
                  <TableHead>金额</TableHead>
                  <TableHead>状态</TableHead>
                  <TableHead>创建时间</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {recentOrders.map((order) => (
                  <TableRow key={order.uid}>
                    <TableCell className="font-medium">
                      {order.pre_order?.number || order.uid.slice(0, 8)}
                    </TableCell>
                    <TableCell>{formatPrice(order.sched_price)}</TableCell>
                    <TableCell>
                      <Badge variant={statusVariant[order.status] || "secondary"}>
                        {statusLabel[order.status] || "未知"}
                      </Badge>
                    </TableCell>
                    <TableCell>{formatDate(order.create_at)}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  )
}
