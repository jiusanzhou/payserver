"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
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
import { RefreshCw, Receipt, TrendingUp, Plus } from "lucide-react"

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

interface Agent {
  uid: string
  device_id: string
  device_info: string
}

export default function RecordsPage() {
  const [records, setRecords] = useState<PayRecord[]>([])
  const [loading, setLoading] = useState(true)
  const [typeFilter, setTypeFilter] = useState<string>("all")
  const [dialogOpen, setDialogOpen] = useState(false)
  const [submitting, setSubmitting] = useState(false)
  const [agents, setAgents] = useState<Agent[]>([])
  const [formData, setFormData] = useState({
    type: "wechat",
    amount: "",
    number: "",
    agent_uid: "",
  })

  const fetchAgents = async () => {
    try {
      const res = await fetch("/api/v1/agents")
      const data = await res.json()
      setAgents(data.agents || [])
    } catch (err) {
      console.error("Failed to fetch agents:", err)
    }
  }

  const handleSubmit = async () => {
    if (!formData.type || !formData.amount) {
      alert("请填写支付渠道和金额")
      return
    }

    const amountCents = Math.round(parseFloat(formData.amount) * 100)
    if (isNaN(amountCents) || amountCents <= 0) {
      alert("请输入有效的金额")
      return
    }

    setSubmitting(true)
    try {
      const res = await fetch("/api/v1/records", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          type: formData.type,
          amount: amountCents,
          number: formData.number || `MANUAL-${Date.now()}`,
          agent_uid: formData.agent_uid || "manual",
          timestamp: new Date().toISOString(),
        }),
      })

      if (!res.ok) {
        const err = await res.json()
        throw new Error(err.error || "创建失败")
      }

      setDialogOpen(false)
      setFormData({ type: "wechat", amount: "", number: "", agent_uid: "" })
      fetchRecords()
    } catch (err) {
      console.error("Failed to create record:", err)
      alert(err instanceof Error ? err.message : "创建失败")
    } finally {
      setSubmitting(false)
    }
  }

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

  useEffect(() => {
    fetchAgents()
  }, [])

  const totalAmount = records.reduce((sum, r) => sum + r.amount, 0)

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">收款记录</h1>
          <p className="text-muted-foreground">查看所有设备上报的收款记录</p>
        </div>
        <div className="flex gap-2">
          <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
            <DialogTrigger asChild>
              <Button size="sm">
                <Plus className="h-4 w-4 mr-2" />
                手动录入
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>手动录入收款</DialogTitle>
                <DialogDescription>
                  手动添加一条收款记录，用于补录线下收款或其他渠道收款
                </DialogDescription>
              </DialogHeader>
              <div className="grid gap-4 py-4">
                <div className="grid gap-2">
                  <Label htmlFor="type">支付渠道 *</Label>
                  <Select
                    value={formData.type}
                    onValueChange={(v) => setFormData((f) => ({ ...f, type: v }))}
                  >
                    <SelectTrigger id="type">
                      <SelectValue placeholder="选择渠道" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="wechat">微信支付</SelectItem>
                      <SelectItem value="alipay">支付宝</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="amount">金额 (元) *</Label>
                  <Input
                    id="amount"
                    type="number"
                    step="0.01"
                    min="0.01"
                    placeholder="例如: 99.99"
                    value={formData.amount}
                    onChange={(e) =>
                      setFormData((f) => ({ ...f, amount: e.target.value }))
                    }
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="number">流水号</Label>
                  <Input
                    id="number"
                    placeholder="可选，留空自动生成"
                    value={formData.number}
                    onChange={(e) =>
                      setFormData((f) => ({ ...f, number: e.target.value }))
                    }
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="agent">关联设备</Label>
                  <Select
                    value={formData.agent_uid}
                    onValueChange={(v) =>
                      setFormData((f) => ({ ...f, agent_uid: v }))
                    }
                  >
                    <SelectTrigger id="agent">
                      <SelectValue placeholder="可选，选择设备" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="manual">手动录入 (无设备)</SelectItem>
                      {agents.map((agent) => (
                        <SelectItem key={agent.uid} value={agent.uid}>
                          {agent.device_info || agent.device_id || agent.uid.slice(0, 8)}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
              <DialogFooter>
                <Button
                  variant="outline"
                  onClick={() => setDialogOpen(false)}
                  disabled={submitting}
                >
                  取消
                </Button>
                <Button onClick={handleSubmit} disabled={submitting}>
                  {submitting ? "提交中..." : "提交"}
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
          <Button onClick={fetchRecords} variant="outline" size="sm">
            <RefreshCw className="h-4 w-4 mr-2" />
            刷新
          </Button>
        </div>
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
