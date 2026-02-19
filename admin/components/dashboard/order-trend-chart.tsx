"use client"

import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts"

interface OrderTrendChartProps {
  data: { date: string; orders: number; paid: number }[]
}

export function OrderTrendChart({ data }: OrderTrendChartProps) {
  return (
    <ResponsiveContainer width="100%" height={300}>
      <AreaChart data={data}>
        <CartesianGrid strokeDasharray="3 3" className="stroke-muted" />
        <XAxis
          dataKey="date"
          className="text-xs"
          tick={{ fill: "hsl(var(--muted-foreground))" }}
        />
        <YAxis
          className="text-xs"
          tick={{ fill: "hsl(var(--muted-foreground))" }}
        />
        <Tooltip
          contentStyle={{
            backgroundColor: "hsl(var(--card))",
            border: "1px solid hsl(var(--border))",
            borderRadius: "var(--radius)",
          }}
          labelStyle={{ color: "hsl(var(--foreground))" }}
        />
        <Area
          type="monotone"
          dataKey="orders"
          name="总订单"
          stackId="1"
          stroke="hsl(var(--muted-foreground))"
          fill="hsl(var(--muted))"
        />
        <Area
          type="monotone"
          dataKey="paid"
          name="已支付"
          stackId="2"
          stroke="hsl(var(--primary))"
          fill="hsl(var(--primary) / 0.3)"
        />
      </AreaChart>
    </ResponsiveContainer>
  )
}
