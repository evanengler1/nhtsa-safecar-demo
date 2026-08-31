"use client"

import {
  Bar, BarChart, CartesianGrid, Cell, Legend, Pie, PieChart,
  ResponsiveContainer, Tooltip, XAxis, YAxis
} from "recharts"
import { ChartTooltip, getYAxisWidth, formatTick } from "@/components/chart-utils"
import { CHART_COLORS, RATING_VAR } from "@/lib/format"
import type { Overview } from "@/lib/types"

const AXIS = { fontSize: 11, fill: "var(--muted-foreground)" }
const GRID = "color-mix(in srgb, var(--border) 70%, transparent)"

const STAR_COLORS: Record<number, string> = {
  5: "var(--status-5star)",
  4: "var(--status-4star)",
  3: "var(--status-3star)",
  2: "var(--status-low)",
  1: "var(--status-low)",
}

export function RatingDistributionChart({ data }: { data: Overview["ratingDistribution"] }) {
  const rows = data.map(d => ({
    name: `${d.stars}-Star`,
    value: d.count,
    fill: STAR_COLORS[d.stars] ?? RATING_VAR.neutral,
  }))

  if (!rows.length) return <EmptyChart message="No rating data" />

  return (
    <ResponsiveContainer width="100%" height={260}>
      <PieChart>
        <Pie data={rows} dataKey="value" nameKey="name" innerRadius={54} outerRadius={88} paddingAngle={2} stroke="var(--card)" strokeWidth={2}>
          {rows.map(r => <Cell key={r.name} fill={r.fill} />)}
        </Pie>
        <Tooltip content={<ChartTooltip />} />
        <Legend verticalAlign="bottom" height={44} iconSize={8}
          formatter={(v: string) => <span style={{ fontSize: 11, color: "var(--muted-foreground)" }}>{v}</span>} />
      </PieChart>
    </ResponsiveContainer>
  )
}

export function ADASTimelineChart({ data }: { data: Overview["adasTimeline"] }) {
  if (!data.length) return <EmptyChart message="No ADAS data" />

  return (
    <ResponsiveContainer width="100%" height={260}>
      <BarChart data={data} margin={{ top: 4, right: 8, bottom: 0, left: 0 }}>
        <CartesianGrid stroke={GRID} vertical={false} />
        <XAxis dataKey="year" tick={AXIS} tickLine={false} axisLine={{ stroke: GRID }} />
        <YAxis tick={AXIS} tickLine={false} axisLine={false} domain={[0, 100]} tickFormatter={(v: number) => `${v}%`} width={44} />
        <Tooltip content={<ChartTooltip />} cursor={{ fill: "color-mix(in srgb, var(--foreground) 6%, transparent)" }} />
        <Legend wrapperStyle={{ fontSize: 11 }} />
        <Bar dataKey="pctCIB" name="Auto-Brake" fill={CHART_COLORS[0]} radius={[3, 3, 0, 0]} maxBarSize={18} />
        <Bar dataKey="pctFCW" name="Fwd Collision Warn" fill={CHART_COLORS[2]} radius={[3, 3, 0, 0]} maxBarSize={18} />
        <Bar dataKey="pctBSD" name="Blind Spot" fill={CHART_COLORS[3]} radius={[3, 3, 0, 0]} maxBarSize={18} />
        <Bar dataKey="pctLDW" name="Lane Departure" fill={CHART_COLORS[4]} radius={[3, 3, 0, 0]} maxBarSize={18} />
      </BarChart>
    </ResponsiveContainer>
  )
}

export function RankedBarChart({
  data, labelKey, valueKey, height = 300, color = "var(--chart-1)", unit = "",
}: {
  data: Record<string, unknown>[]; labelKey: string; valueKey: string;
  height?: number; color?: string; unit?: string;
}) {
  if (!data.length) return <EmptyChart message="No data available" />

  return (
    <ResponsiveContainer width="100%" height={height}>
      <BarChart data={data} layout="vertical" margin={{ top: 0, right: 16, bottom: 0, left: 0 }}>
        <CartesianGrid stroke={GRID} horizontal={false} />
        <XAxis type="number" tick={AXIS} tickLine={false} axisLine={{ stroke: GRID }}
          tickFormatter={(v: number) => unit === "%" ? `${v}%` : formatTick(v)} />
        <YAxis type="category" dataKey={labelKey} tick={AXIS} tickLine={false} axisLine={false} width={80} />
        <Tooltip content={<ChartTooltip />} cursor={{ fill: "color-mix(in srgb, var(--foreground) 6%, transparent)" }} />
        <Bar dataKey={valueKey} fill={color} radius={[0, 3, 3, 0]} maxBarSize={22} />
      </BarChart>
    </ResponsiveContainer>
  )
}

export function EmptyChart({ message }: { message: string }) {
  return (
    <div className="flex h-[220px] items-center justify-center rounded border border-dashed border-border text-xs text-muted-foreground">
      {message}
    </div>
  )
}
