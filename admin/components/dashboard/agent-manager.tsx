"use client"

import { useState, useEffect } from "react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
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
import { Plus, Trash2, Save, Wifi, WifiOff } from "lucide-react"

interface Agent {
  uid: string
  device_id: string
  device_info: string
  status: number
  heartbeat_at: string
  weight?: number
}

interface AppAgentBind {
  agent_uid: string
  weight: number
  agent?: Agent
}

interface AgentManagerProps {
  appUid: string
  appName: string
  open: boolean
  onOpenChange: (open: boolean) => void
  onUpdate?: () => void
}

export function AgentManager({
  appUid,
  appName,
  open,
  onOpenChange,
  onUpdate,
}: AgentManagerProps) {
  const [bindings, setBindings] = useState<AppAgentBind[]>([])
  const [availableAgents, setAvailableAgents] = useState<Agent[]>([])
  const [loading, setLoading] = useState(false)
  const [saving, setSaving] = useState(false)
  const [selectedAgent, setSelectedAgent] = useState<string>("")
  const [newWeight, setNewWeight] = useState(1)

  const fetchData = async () => {
    setLoading(true)
    try {
      const [bindingsRes, agentsRes] = await Promise.all([
        fetch(`/api/v1/apps/${appUid}/agents`),
        fetch("/api/v1/agents?limit=100"),
      ])
      const bindingsData = await bindingsRes.json()
      const agentsData = await agentsRes.json()

      setBindings(bindingsData.bindings || [])
      setAvailableAgents(agentsData.agents || [])
    } catch (err) {
      console.error("Failed to fetch data:", err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (open) {
      fetchData()
    }
  }, [open, appUid])

  const isOnline = (heartbeatAt: string) => {
    const diff = Date.now() - new Date(heartbeatAt).getTime()
    return diff < 5 * 60 * 1000
  }

  const handleAddAgent = async () => {
    if (!selectedAgent) return
    try {
      await fetch(`/api/v1/apps/${appUid}/agents`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          agent_uid: selectedAgent,
          weight: newWeight,
        }),
      })
      setSelectedAgent("")
      setNewWeight(1)
      fetchData()
      onUpdate?.()
    } catch (err) {
      console.error("Failed to add agent:", err)
    }
  }

  const handleRemoveAgent = async (agentUid: string) => {
    try {
      await fetch(`/api/v1/apps/${appUid}/agents/${agentUid}`, {
        method: "DELETE",
      })
      fetchData()
      onUpdate?.()
    } catch (err) {
      console.error("Failed to remove agent:", err)
    }
  }

  const handleUpdateWeight = async (agentUid: string, weight: number) => {
    setSaving(true)
    try {
      await fetch(`/api/v1/apps/${appUid}/agents/${agentUid}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ weight }),
      })
      fetchData()
    } catch (err) {
      console.error("Failed to update weight:", err)
    } finally {
      setSaving(false)
    }
  }

  // Filter out already bound agents
  const boundAgentUids = new Set(bindings.map((b) => b.agent_uid))
  const unboundAgents = availableAgents.filter(
    (a) => !boundAgentUids.has(a.uid) && a.status === 1
  )

  // Calculate total weight for percentage
  const totalWeight = bindings.reduce((sum, b) => sum + (b.weight || 1), 0)

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl">
        <DialogHeader>
          <DialogTitle>设备调度管理 - {appName}</DialogTitle>
          <DialogDescription>
            管理应用绑定的收款设备及其调度权重。权重越高，分配订单的概率越大。
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4">
          {/* Add Agent Section */}
          <div className="flex items-end gap-2 p-4 border rounded-lg bg-muted/50">
            <div className="flex-1 space-y-2">
              <Label>添加设备</Label>
              <Select value={selectedAgent} onValueChange={setSelectedAgent}>
                <SelectTrigger>
                  <SelectValue placeholder="选择设备" />
                </SelectTrigger>
                <SelectContent>
                  {unboundAgents.length === 0 ? (
                    <SelectItem value="_none" disabled>
                      暂无可用设备
                    </SelectItem>
                  ) : (
                    unboundAgents.map((agent) => (
                      <SelectItem key={agent.uid} value={agent.uid}>
                        {agent.device_info || agent.device_id.slice(0, 12)}
                        {isOnline(agent.heartbeat_at) ? " (在线)" : " (离线)"}
                      </SelectItem>
                    ))
                  )}
                </SelectContent>
              </Select>
            </div>
            <div className="w-24 space-y-2">
              <Label>权重</Label>
              <Input
                type="number"
                min={1}
                max={100}
                value={newWeight}
                onChange={(e) => setNewWeight(parseInt(e.target.value) || 1)}
              />
            </div>
            <Button onClick={handleAddAgent} disabled={!selectedAgent}>
              <Plus className="h-4 w-4 mr-1" />
              添加
            </Button>
          </div>

          {/* Bindings Table */}
          {loading ? (
            <div className="text-center py-8 text-muted-foreground">
              加载中...
            </div>
          ) : bindings.length === 0 ? (
            <div className="text-center py-8 text-muted-foreground">
              暂未绑定设备
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>设备</TableHead>
                  <TableHead>状态</TableHead>
                  <TableHead className="w-32">权重</TableHead>
                  <TableHead className="w-24">占比</TableHead>
                  <TableHead className="w-20">操作</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {bindings.map((binding) => {
                  const agent = binding.agent || availableAgents.find(a => a.uid === binding.agent_uid)
                  const online = agent ? isOnline(agent.heartbeat_at) : false
                  const percentage = totalWeight > 0 
                    ? Math.round((binding.weight / totalWeight) * 100) 
                    : 0

                  return (
                    <TableRow key={binding.agent_uid}>
                      <TableCell>
                        <div>
                          <div className="font-medium">
                            {agent?.device_info || binding.agent_uid.slice(0, 12)}
                          </div>
                          <div className="text-xs text-muted-foreground font-mono">
                            {binding.agent_uid.slice(0, 16)}...
                          </div>
                        </div>
                      </TableCell>
                      <TableCell>
                        {online ? (
                          <Badge variant="success" className="gap-1">
                            <Wifi className="h-3 w-3" />
                            在线
                          </Badge>
                        ) : (
                          <Badge variant="secondary" className="gap-1">
                            <WifiOff className="h-3 w-3" />
                            离线
                          </Badge>
                        )}
                      </TableCell>
                      <TableCell>
                        <div className="flex items-center gap-1">
                          <Input
                            type="number"
                            min={1}
                            max={100}
                            defaultValue={binding.weight}
                            className="w-16 h-8"
                            onBlur={(e) => {
                              const val = parseInt(e.target.value) || 1
                              if (val !== binding.weight) {
                                handleUpdateWeight(binding.agent_uid, val)
                              }
                            }}
                          />
                          {saving && (
                            <Save className="h-3 w-3 animate-pulse text-muted-foreground" />
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <Badge variant="outline">{percentage}%</Badge>
                      </TableCell>
                      <TableCell>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => handleRemoveAgent(binding.agent_uid)}
                          className="text-destructive hover:text-destructive"
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </TableCell>
                    </TableRow>
                  )
                })}
              </TableBody>
            </Table>
          )}

          {/* Weight Explanation */}
          <div className="text-xs text-muted-foreground p-3 bg-muted/50 rounded">
            <strong>调度说明：</strong>
            创建订单时，系统会根据权重比例随机选择一台在线设备。
            例如：设备A权重2，设备B权重1，则A有约67%概率被选中，B有约33%概率被选中。
          </div>
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            关闭
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}
