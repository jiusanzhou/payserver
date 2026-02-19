"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
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
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { formatDate } from "@/lib/utils"
import { RefreshCw, Plus, Trash2, Settings, Copy, Eye, EyeOff } from "lucide-react"
import { AgentManager } from "@/components/dashboard"

interface App {
  uid: string
  name: string
  description: string
  callback_url: string
  secret: string
  price_floor: number
  price_ceil: number
  expire_in: number
  max_pendding_order: number
  agents?: { uid: string; device_id: string }[]
  create_at: string
}

export default function AppsPage() {
  const [apps, setApps] = useState<App[]>([])
  const [loading, setLoading] = useState(true)
  const [showSecret, setShowSecret] = useState<Record<string, boolean>>({})
  const [dialogOpen, setDialogOpen] = useState(false)
  const [managerOpen, setManagerOpen] = useState(false)
  const [selectedApp, setSelectedApp] = useState<App | null>(null)
  const [newApp, setNewApp] = useState({
    name: "",
    callback_url: "",
    description: "",
    price_floor: 2,
    price_ceil: 2,
    expire_in: 300,
    max_pendding_order: 10,
  })

  const fetchApps = async () => {
    setLoading(true)
    try {
      const res = await fetch("/api/v1/apps")
      const data = await res.json()
      setApps(data.apps || [])
    } catch (err) {
      console.error("Failed to fetch apps:", err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    fetchApps()
  }, [])

  const handleCreate = async () => {
    try {
      await fetch("/api/v1/apps", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(newApp),
      })
      setDialogOpen(false)
      setNewApp({
        name: "",
        callback_url: "",
        description: "",
        price_floor: 2,
        price_ceil: 2,
        expire_in: 300,
        max_pendding_order: 10,
      })
      fetchApps()
    } catch (err) {
      console.error("Failed to create app:", err)
    }
  }

  const handleDelete = async (uid: string) => {
    if (!confirm("确定要删除此应用吗？相关的订单数据不会被删除。")) return
    try {
      await fetch(`/api/v1/apps/${uid}`, { method: "DELETE" })
      fetchApps()
    } catch (err) {
      console.error("Failed to delete app:", err)
    }
  }

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text)
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold tracking-tight">应用管理</h1>
          <p className="text-muted-foreground">管理接入的商户应用</p>
        </div>
        <div className="flex gap-2">
          <Button onClick={fetchApps} variant="outline" size="sm">
            <RefreshCw className="h-4 w-4 mr-2" />
            刷新
          </Button>
          <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
            <DialogTrigger asChild>
              <Button size="sm">
                <Plus className="h-4 w-4 mr-2" />
                新建应用
              </Button>
            </DialogTrigger>
            <DialogContent>
              <DialogHeader>
                <DialogTitle>新建应用</DialogTitle>
                <DialogDescription>
                  创建一个新的商户应用，用于接入收款服务
                </DialogDescription>
              </DialogHeader>
              <div className="grid gap-4 py-4">
                <div className="grid gap-2">
                  <Label htmlFor="name">应用名称 *</Label>
                  <Input
                    id="name"
                    value={newApp.name}
                    onChange={(e) => setNewApp({ ...newApp, name: e.target.value })}
                    placeholder="我的商城"
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="callback">回调地址 *</Label>
                  <Input
                    id="callback"
                    value={newApp.callback_url}
                    onChange={(e) => setNewApp({ ...newApp, callback_url: e.target.value })}
                    placeholder="https://your-site.com/api/pay/callback"
                  />
                </div>
                <div className="grid gap-2">
                  <Label htmlFor="desc">描述</Label>
                  <Input
                    id="desc"
                    value={newApp.description}
                    onChange={(e) => setNewApp({ ...newApp, description: e.target.value })}
                    placeholder="可选描述"
                  />
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="floor">价格下浮 (分)</Label>
                    <Input
                      id="floor"
                      type="number"
                      value={newApp.price_floor}
                      onChange={(e) => setNewApp({ ...newApp, price_floor: parseInt(e.target.value) })}
                    />
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="ceil">价格上浮 (分)</Label>
                    <Input
                      id="ceil"
                      type="number"
                      value={newApp.price_ceil}
                      onChange={(e) => setNewApp({ ...newApp, price_ceil: parseInt(e.target.value) })}
                    />
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-4">
                  <div className="grid gap-2">
                    <Label htmlFor="expire">过期时间 (秒)</Label>
                    <Input
                      id="expire"
                      type="number"
                      value={newApp.expire_in}
                      onChange={(e) => setNewApp({ ...newApp, expire_in: parseInt(e.target.value) })}
                    />
                  </div>
                  <div className="grid gap-2">
                    <Label htmlFor="maxOrder">最大待付订单</Label>
                    <Input
                      id="maxOrder"
                      type="number"
                      value={newApp.max_pendding_order}
                      onChange={(e) => setNewApp({ ...newApp, max_pendding_order: parseInt(e.target.value) })}
                    />
                  </div>
                </div>
              </div>
              <DialogFooter>
                <Button variant="outline" onClick={() => setDialogOpen(false)}>
                  取消
                </Button>
                <Button onClick={handleCreate} disabled={!newApp.name || !newApp.callback_url}>
                  创建
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>应用列表</CardTitle>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="text-center py-8 text-muted-foreground">加载中...</div>
          ) : apps.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">暂无应用</div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>应用名称</TableHead>
                  <TableHead>AppID</TableHead>
                  <TableHead>Secret</TableHead>
                  <TableHead>回调地址</TableHead>
                  <TableHead>绑定设备</TableHead>
                  <TableHead>创建时间</TableHead>
                  <TableHead>操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {apps.map((app) => (
                  <TableRow key={app.uid}>
                    <TableCell className="font-medium">{app.name}</TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <code className="text-xs bg-muted px-1 py-0.5 rounded">
                          {app.uid.slice(0, 8)}...
                        </code>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-6 w-6 p-0"
                          onClick={() => copyToClipboard(app.uid)}
                        >
                          <Copy className="h-3 w-3" />
                        </Button>
                      </div>
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center gap-1">
                        <code className="text-xs bg-muted px-1 py-0.5 rounded">
                          {showSecret[app.uid] ? app.secret : "••••••••"}
                        </code>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-6 w-6 p-0"
                          onClick={() => setShowSecret({ ...showSecret, [app.uid]: !showSecret[app.uid] })}
                        >
                          {showSecret[app.uid] ? <EyeOff className="h-3 w-3" /> : <Eye className="h-3 w-3" />}
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="h-6 w-6 p-0"
                          onClick={() => copyToClipboard(app.secret)}
                        >
                          <Copy className="h-3 w-3" />
                        </Button>
                      </div>
                    </TableCell>
                    <TableCell className="max-w-48 truncate text-muted-foreground text-xs">
                      {app.callback_url}
                    </TableCell>
                    <TableCell>
                      <Badge variant="secondary">
                        {app.agents?.length || 0} 台
                      </Badge>
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">
                      {formatDate(app.create_at)}
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-1">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => {
                            setSelectedApp(app)
                            setManagerOpen(true)
                          }}
                        >
                          <Settings className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleDelete(app.uid)}
                          className="text-destructive hover:text-destructive"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>

      {/* Agent Manager Dialog */}
      {selectedApp && (
        <AgentManager
          appUid={selectedApp.uid}
          appName={selectedApp.name}
          open={managerOpen}
          onOpenChange={setManagerOpen}
          onUpdate={fetchApps}
        />
      )}
    </div>
  )
}
