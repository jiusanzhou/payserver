"use client"

import { useState, useEffect } from "react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { QrCode, RefreshCw, CheckCircle, Clock } from "lucide-react"

interface QRCodeData {
  name: string
  host: string
  version: string
  ticket: string
}

interface AgentBindQRProps {
  onSuccess?: () => void
}

export function AgentBindQR({ onSuccess }: AgentBindQRProps) {
  const [open, setOpen] = useState(false)
  const [qrData, setQrData] = useState<QRCodeData | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [polling, setPolling] = useState(false)
  const [bound, setBound] = useState(false)

  const generateQR = async () => {
    setLoading(true)
    setError(null)
    setBound(false)
    try {
      const res = await fetch("/api/v1/agents/prepare", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ device_id: `pending-${Date.now()}` }),
      })
      if (!res.ok) {
        const data = await res.json()
        throw new Error(data.message || "生成失败")
      }
      const data = await res.json()
      setQrData(data)
      setPolling(true)
    } catch (err) {
      setError(err instanceof Error ? err.message : "生成二维码失败")
    } finally {
      setLoading(false)
    }
  }

  // Poll for agent registration status
  useEffect(() => {
    if (!polling || !qrData?.ticket) return

    const interval = setInterval(async () => {
      try {
        const res = await fetch(`/api/v1/agents/ticket/${qrData.ticket}/status`)
        const data = await res.json()
        if (data.registered) {
          setPolling(false)
          setBound(true)
          onSuccess?.()
        }
      } catch {
        // Ignore polling errors
      }
    }, 2000)

    return () => clearInterval(interval)
  }, [polling, qrData?.ticket, onSuccess])

  // Generate QR on open
  useEffect(() => {
    if (open && !qrData) {
      generateQR()
    }
  }, [open])

  const handleClose = () => {
    setOpen(false)
    setPolling(false)
    setQrData(null)
    setBound(false)
  }

  // Generate QR code SVG using a simple implementation
  const qrCodeUrl = qrData
    ? `https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(
        JSON.stringify(qrData)
      )}`
    : null

  return (
    <Dialog open={open} onOpenChange={(v) => (v ? setOpen(true) : handleClose())}>
      <DialogTrigger asChild>
        <Button>
          <QrCode className="h-4 w-4 mr-2" />
          添加设备
        </Button>
      </DialogTrigger>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>扫码绑定设备</DialogTitle>
          <DialogDescription>
            使用 PayServer Agent App 扫描下方二维码完成设备绑定
          </DialogDescription>
        </DialogHeader>

        <div className="flex flex-col items-center space-y-4 py-4">
          {loading && (
            <div className="w-[200px] h-[200px] flex items-center justify-center border rounded-lg bg-muted">
              <RefreshCw className="h-8 w-8 animate-spin text-muted-foreground" />
            </div>
          )}

          {error && (
            <div className="w-[200px] h-[200px] flex flex-col items-center justify-center border rounded-lg bg-destructive/10 text-destructive">
              <p className="text-sm text-center px-4">{error}</p>
              <Button variant="outline" size="sm" className="mt-2" onClick={generateQR}>
                重试
              </Button>
            </div>
          )}

          {bound && (
            <div className="w-[200px] h-[200px] flex flex-col items-center justify-center border rounded-lg bg-green-50 dark:bg-green-950">
              <CheckCircle className="h-12 w-12 text-green-500" />
              <p className="text-sm text-green-600 dark:text-green-400 mt-2">绑定成功</p>
            </div>
          )}

          {!loading && !error && !bound && qrCodeUrl && (
            <>
              <div className="border rounded-lg p-2 bg-white">
                <img
                  src={qrCodeUrl}
                  alt="Bind QR Code"
                  width={200}
                  height={200}
                  className="rounded"
                />
              </div>
              <div className="flex items-center text-sm text-muted-foreground">
                <Clock className="h-4 w-4 mr-1 animate-pulse" />
                等待设备扫码...
              </div>
            </>
          )}
        </div>

        <div className="flex justify-between">
          <Button variant="outline" onClick={handleClose}>
            取消
          </Button>
          {!bound && !loading && (
            <Button variant="outline" onClick={generateQR}>
              <RefreshCw className="h-4 w-4 mr-2" />
              刷新二维码
            </Button>
          )}
          {bound && (
            <Button onClick={handleClose}>
              完成
            </Button>
          )}
        </div>
      </DialogContent>
    </Dialog>
  )
}
