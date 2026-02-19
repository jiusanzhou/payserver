"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import {
  LayoutDashboard,
  ShoppingCart,
  Smartphone,
  AppWindow,
  Receipt,
  Settings,
  LogOut,
} from "lucide-react"
import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"

const navItems = [
  {
    title: "概览",
    href: "/",
    icon: LayoutDashboard,
  },
  {
    title: "订单",
    href: "/orders",
    icon: ShoppingCart,
  },
  {
    title: "设备",
    href: "/agents",
    icon: Smartphone,
  },
  {
    title: "应用",
    href: "/apps",
    icon: AppWindow,
  },
  {
    title: "收款记录",
    href: "/records",
    icon: Receipt,
  },
]

export function Sidebar() {
  const pathname = usePathname()

  return (
    <div className="flex h-full w-64 flex-col border-r bg-background">
      <div className="flex h-14 items-center border-b px-4">
        <Link href="/" className="flex items-center gap-2 font-semibold">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary text-primary-foreground">
            P
          </div>
          <span>PayServer</span>
        </Link>
      </div>

      <nav className="flex-1 space-y-1 p-4">
        {navItems.map((item) => {
          const isActive = pathname === item.href
          return (
            <Link key={item.href} href={item.href}>
              <Button
                variant={isActive ? "secondary" : "ghost"}
                className={cn(
                  "w-full justify-start gap-2",
                  isActive && "bg-secondary"
                )}
              >
                <item.icon className="h-4 w-4" />
                {item.title}
              </Button>
            </Link>
          )
        })}
      </nav>

      <Separator />

      <div className="p-4 space-y-1">
        <Link href="/settings">
          <Button variant="ghost" className="w-full justify-start gap-2">
            <Settings className="h-4 w-4" />
            设置
          </Button>
        </Link>
        <Button variant="ghost" className="w-full justify-start gap-2 text-destructive">
          <LogOut className="h-4 w-4" />
          退出登录
        </Button>
      </div>
    </div>
  )
}
