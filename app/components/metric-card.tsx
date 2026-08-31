import type React from "react"
import { Skeleton } from "@/components/ui/skeleton"

/**
 * KPI tile for the executive header row.
 *
 * `accent` drives the left rule and value color so alert metrics (expiring,
 * expired) read differently from neutral portfolio metrics at a glance.
 */
export function MetricCard({
  label,
  value,
  sub,
  accent,
  icon,
  loading = false,
}: {
  label: string
  value: React.ReactNode
  sub?: React.ReactNode
  accent?: string
  icon?: React.ReactNode
  loading?: boolean
}) {
  return (
    <div
      className="relative overflow-hidden rounded-lg border border-border bg-card p-4"
      style={accent ? { boxShadow: `inset 3px 0 0 0 ${accent}` } : undefined}
    >
      <div className="flex items-start justify-between gap-2">
        <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
          {label}
        </p>
        {icon && <span className="shrink-0 text-muted-foreground">{icon}</span>}
      </div>

      {loading ? (
        <Skeleton className="mt-2 h-8 w-24" />
      ) : (
        <p
          className="nums mt-2 text-2xl font-semibold tracking-tight"
          style={accent ? { color: accent } : undefined}
        >
          {value}
        </p>
      )}

      {loading ? (
        <Skeleton className="mt-2 h-3 w-32" />
      ) : (
        sub && <p className="mt-1 text-xs text-muted-foreground">{sub}</p>
      )}
    </div>
  )
}

/** Section wrapper giving every panel a consistent header and border. */
export function Panel({
  title,
  description,
  actions,
  children,
  className = "",
  bodyClassName = "",
}: {
  title: string
  description?: string
  actions?: React.ReactNode
  children: React.ReactNode
  className?: string
  bodyClassName?: string
}) {
  return (
    <section className={`rounded-lg border border-border bg-card ${className}`}>
      <header className="flex items-start justify-between gap-3 border-b border-border px-4 py-3">
        <div className="min-w-0">
          <h2 className="text-sm font-semibold tracking-tight">{title}</h2>
          {description && (
            <p className="mt-0.5 text-xs text-muted-foreground">{description}</p>
          )}
        </div>
        {actions && <div className="shrink-0">{actions}</div>}
      </header>
      <div className={`p-4 ${bodyClassName}`}>{children}</div>
    </section>
  )
}
