"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { formatPrice, formatDate } from "@/lib/utils"
import { RefreshCw, Receipt, TrendingUp } from "lucide-react"

interface PayRecord {
  uid: string
  agent_uid: string
  type: string
  number: string
  amount: number
  timestamp: string
  create_at: string
}

const payTypeLabel: Record<string, string> = {
  wechat: "微信",
  alipay: "支付宝",
}

const payTypeVariant: Record<string, "success" | "default"> = {
  wechat: "success",
  alipay: "default",
}

export default function RecordsPage() {
  const [records, setRecords] = useState<PayRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [typeFilter, setTypeFilter] = useState<string>("all")

  const fetchRecords = async () => {
    setLoading(true)
    try {
      const params = new URLSearchParams()
      if (typeFilter !== "all") {
        params.set("method", typeFilter)
      }
      const res = await fetch(`/api/v1/records?${params}`)
      const data = await res.json()
      setRecords(data.records || [])
    } catch (err) {
      console.error("Failed to fetch records:", err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchRecords()
  }, [typeFilter])

  const totalAmount = records.reduce((sum, r) => sum + r.amount, 0)

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">收款记录</h1>
          <p className="text-muted-foreground">查看所有设备上报的收款记录</p>
        </div>
        <Button onClick={fetchRecords} variant="outline" size="sm">
          <RefreshCw className="h-4 w-4 mr-2" />
          刷新
        </Button>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">记录总数</CardTitle>
            <Receipt className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{records.length}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">收款总额</CardTitle>
            <TrendingUp className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{formatPrice(totalAmount)}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">筛选</CardTitle>
          </CardHeader>
          <CardContent>
            <Select value={typeFilter} onValueChange={setTypeFilter}>
              <SelectTrigger>
                <SelectValue placeholder="支付方式" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">全部</SelectItem>
                <SelectItem value="wechat">微信支付</SelectItem>
                <SelectItem value="alipay">支付宝</SelectItem>
              </SelectContent>
            </Select>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>记录列表</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8 text-muted-foreground">加载中...</div>
          ) : records.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">暂无记录</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>记录ID</TableHead>
                  <TableHead>流水号</TableHead>
                  <TableHead>金额</TableHead>
                  <TableHead>支付方式</TableHead>
                  <TableHead>设备</TableHead>
                  <TableHead>收款时间</TableHead>
                  <TableHead>上报时间</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {records.map((record) => (
                  <TableRow key={record.uid}>
                    <TableCell className="font-mono text-xs">
                      {record.uid.slice(0, 8)}...
                    </TableCell>
                    <TableCell className="font-mono text-xs">
                      {record.number || "-"}
                    </TableCell>
                    <TableCell className="font-medium text-green-600">
                      +{formatPrice(record.amount)}
                    </TableCell>
                    <TableCell>
                      <Badge variant={payTypeVariant[record.type] || "secondary"}>
                        {payTypeLabel[record.type] || record.type}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-muted-foreground text-xs">
                      {record.agent_uid.slice(0, 8)}...
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">
                      {formatDate(record.timestamp)}
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">
                      {formatDate(record.create_at)}
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
