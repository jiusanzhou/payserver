"use client"

import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts"

interface OrderStatsChartProps {
  data: { status: string; count: number }[]
}

const STATUS_COLORS: Record<string, string> = {
  "待支付": "hsl(var(--warning))",
  "已支付": "hsl(var(--success))",
  "已过期": "hsl(var(--muted-foreground))",
  "已取消": "hsl(var(--destructive))",
}

export function OrderStatsChart({ data }: OrderStatsChartProps) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <BarChart data={data} layout="vertical">
        <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
        <XAxis
          type="number"
          className="text-xs"
          tick={{ fill: "hsl(var(--muted-foreground))" }}
        />
        <YAxis
          type="category"
          dataKey="status"
          className="text-xs"
          tick={{ fill: "hsl(var(--muted-foreground))" }}
          width={60}
        />
        <Tooltip
          contentStyle={{
            backgroundColor: "hsl(var(--card))",
            border: "1px solid hsl(var(--border))",
            borderRadius: "var(--radius)",
          }}
          labelStyle={{ color: "hsl(var(--foreground))" }}
          formatter={(value: number) => [value, "订单数"]}
        />
        <Bar dataKey="count" radius={[0, 4, 4, 0]}>
          {data.map((entry, index) => (
            <Cell
              key={`cell-${index}`}
              fill={STATUS_COLORS[entry.status] || "hsl(var(--primary))"}
            />
          ))}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  )
}
