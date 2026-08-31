"use client"

import Link from "next/link"
import { usePathname } from "next/navigation"
import { LayoutDashboard, Search } from "lucide-react"
import { ThemeToggle } from "@/components/theme-toggle"

const NAV = [
  { href: "/", label: "Overview", icon: LayoutDashboard },
  { href: "/vehicles", label: "Vehicle Search", icon: Search },
]

export function AppHeader() {
  const path = usePathname()

  return (
    <header
      className="sticky top-0 z-40 flex h-14 items-center gap-4 px-4"
      style={{ background: "var(--brand-nav-bg)", color: "var(--brand-nav-fg)" }}
    >
      <span className="text-sm font-bold tracking-tight whitespace-nowrap">NHTSA Fleet Safety</span>

      <nav className="flex items-center gap-1 ml-4">
        {NAV.map((n) => {
          const active = path === n.href
          return (
            <Link
              key={n.href}
              href={n.href}
              className="flex items-center gap-1.5 rounded-md px-3 py-1.5 text-xs font-medium transition-colors"
              style={{
                opacity: active ? 1 : 0.75,
                background: active ? "color-mix(in srgb, var(--brand-nav-fg) 16%, transparent)" : "transparent",
                color: "var(--brand-nav-fg)",
              }}
            >
              <n.icon size={14} />
              {n.label}
            </Link>
          )
        })}
      </nav>

      <div className="ml-auto flex items-center gap-3">
        <span className="hidden md:block text-xs opacity-60">National Highway Traffic Safety Administration</span>
        <ThemeToggle />
      </div>
    </header>
  )
}
