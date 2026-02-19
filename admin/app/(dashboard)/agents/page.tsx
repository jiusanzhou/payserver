"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { formatDate } from "@/lib/utils"
import { RefreshCw, Trash2, Smartphone, Wifi, WifiOff } from "lucide-react"

interface Agent {
  uid: string
  device_id: string
  device_info: string
  pay_types: string
  status: number
  heartbeat_at: string
  create_at: string
}

const statusVariant: Record<number, "success" | "secondary" | "warning"> = {
  0: "warning",   // pending
  1: "success",   // normal
  2: "secondary", // disabled
}

const statusLabel: Record<number, string> = {
  0: "待激活",
  1: "正常",
  2: "已禁用",
}

export default function AgentsPage() {
  const [agents, setAgents] = useState<Agent[]>([])
  const [loading, setLoading] = useState(true)

  const fetchAgents = async () => {
    setLoading(true)
    try {
      const res = await fetch("/api/v1/agents")
      const data = await res.json()
      setAgents(data.agents || [])
    } catch (err) {
      console.error("Failed to fetch agents:", err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchAgents()
  }, [])

  const handleDelete = async (uid: string) => {
    if (!confirm("确定要删除此设备吗？")) return
    try {
      await fetch(`/api/v1/agents/${uid}`, { method: "DELETE" })
      fetchAgents()
    } catch (err) {
      console.error("Failed to delete agent:", err)
    }
  }

  const isOnline = (heartbeatAt: string) => {
    const diff = Date.now() - new Date(heartbeatAt).getTime()
    return diff < 5 * 60 * 1000 // 5 minutes
  }

  const payTypeLabels: Record<string, string> = {
    wechat: "微信",
    alipay: "支付宝",
  }

  const formatPayTypes = (types: string) => {
    return types.split(",").map(t => payTypeLabels[t.trim()] || t).join(", ")
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">设备管理</h1>
          <p className="text-muted-foreground">管理收款设备 (Agent)</p>
        </div>
        <Button onClick={fetchAgents} variant="outline" size="sm">
          <RefreshCw className="h-4 w-4 mr-2" />
          刷新
        </Button>
      </div>

      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">总设备数</CardTitle>
            <Smartphone className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{agents.length}</div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">在线设备</CardTitle>
            <Wifi className="h-4 w-4 text-green-500" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {agents.filter(a => a.status === 1 && isOnline(a.heartbeat_at)).length}
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">离线设备</CardTitle>
            <WifiOff className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {agents.filter(a => a.status === 1 && !isOnline(a.heartbeat_at)).length}
            </div>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>设备列表</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8 text-muted-foreground">加载中...</div>
          ) : agents.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">暂无设备</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>设备ID</TableHead>
                  <TableHead>设备信息</TableHead>
                  <TableHead>支付方式</TableHead>
                  <TableHead>状态</TableHead>
                  <TableHead>在线状态</TableHead>
                  <TableHead>最后心跳</TableHead>
                  <TableHead>注册时间</TableHead>
                  <TableHead>操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {agents.map((agent) => (
                  <TableRow key={agent.uid}>
                    <TableCell className="font-mono text-xs">
                      {agent.device_id.slice(0, 12)}...
                    </TableCell>
                    <TableCell className="max-w-32 truncate">
                      {agent.device_info || "-"}
                    </TableCell>
                    <TableCell>{formatPayTypes(agent.pay_types)}</TableCell>
                    <TableCell>
                      <Badge variant={statusVariant[agent.status] || "secondary"}>
                        {statusLabel[agent.status] || "未知"}
                      </Badge>
                    </TableCell>
                    <TableCell>
                      {agent.status === 1 && isOnline(agent.heartbeat_at) ? (
                        <Badge variant="success">在线</Badge>
                      ) : (
                        <Badge variant="secondary">离线</Badge>
                      )}
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">
                      {formatDate(agent.heartbeat_at)}
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">
                      {formatDate(agent.create_at)}
                    </TableCell>
                    <TableCell>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleDelete(agent.uid)}
                        className="text-destructive hover:text-destructive"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
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
