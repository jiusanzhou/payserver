"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { formatPrice, formatDate } from "@/lib/utils"
import { Search, RefreshCw, XCircle } from "lucide-react"
import type { Order } from "@/lib/api/backend"

const statusVariant: Record<number, "success" | "warning" | "secondary" | "destructive"> = {
  1: "warning",   // pending
  2: "success",   // paid
  3: "secondary", // expired
  4: "destructive", // canceled
}

const statusLabel: Record<number, string> = {
  1: "待支付",
  2: "已支付",
  3: "已过期",
  4: "已取消",
}

const payTypeLabel: Record<string, string> = {
  wechat: "微信",
  alipay: "支付宝",
}

export default function OrdersPage() {
  const [orders, setOrders] = useState<Order[]>([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState("")
  const [statusFilter, setStatusFilter] = useState<string>("all")

  const fetchOrders = async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      if (statusFilter !== "all") {
        params.set("status", statusFilter)
      }
      const res = await fetch(`/api/v1/orders?${params}`)
      const data = await res.json()
      setOrders(data.orders || [])
    } catch (err) {
      console.error("Failed to fetch orders:", err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchOrders()
  }, [statusFilter])

  const handleCancel = async (uid: string) => {
    if (!confirm("确定要取消此订单吗？")) return
    try {
      await fetch(`/api/v1/orders/${uid}/cancel`, { method: "POST" })
      fetchOrders()
    } catch (err) {
      console.error("Failed to cancel order:", err)
    }
  }

  const filteredOrders = orders.filter(order =>
    order.pre_order?.number?.includes(search) ||
    order.uid.includes(search)
  )

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">订单管理</h1>
          <p className="text-muted-foreground">查看和管理所有支付订单</p>
        </div>
        <Button onClick={fetchOrders} variant="outline" size="sm">
          <RefreshCw className="h-4 w-4 mr-2" />
          刷新
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>订单列表</CardTitle>
            <div className="flex items-center gap-2">
              <div className="relative">
                <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="搜索订单号..."
                  className="pl-8 w-64"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </div>
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-32">
                  <SelectValue placeholder="状态筛选" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">全部状态</SelectItem>
                  <SelectItem value="pending">待支付</SelectItem>
                  <SelectItem value="paid">已支付</SelectItem>
                  <SelectItem value="expired">已过期</SelectItem>
                  <SelectItem value="canceled">已取消</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8 text-muted-foreground">加载中...</div>
          ) : filteredOrders.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">暂无订单</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>订单号</TableHead>
                  <TableHead>商品名称</TableHead>
                  <TableHead>原价</TableHead>
                  <TableHead>实付</TableHead>
                  <TableHead>支付方式</TableHead>
                  <TableHead>状态</TableHead>
                  <TableHead>创建时间</TableHead>
                  <TableHead>操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {filteredOrders.map((order) => (
                  <TableRow key={order.uid}>
                    <TableCell className="font-medium font-mono text-xs">
                      {order.pre_order?.number || order.uid.slice(0, 8)}
                    </TableCell>
                    <TableCell>{order.pre_order?.name || "-"}</TableCell>
                    <TableCell>{formatPrice(order.pre_order?.price || 0)}</TableCell>
                    <TableCell className="font-medium">
                      {formatPrice(order.sched_price)}
                    </TableCell>
                    <TableCell>
                      {payTypeLabel[order.sched_pay_type] || order.sched_pay_type}
                    </TableCell>
                    <TableCell>
                      <Badge variant={statusVariant[order.status] || "secondary"}>
                        {statusLabel[order.status] || "未知"}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">
                      {formatDate(order.create_at)}
                    </TableCell>
                    <TableCell>
                      {order.status === 1 && (
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleCancel(order.uid)}
                          className="text-destructive hover:text-destructive"
                        >
                          <XCircle className="h-4 w-4" />
                        </Button>
                      )}
                    </TableCell>
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
