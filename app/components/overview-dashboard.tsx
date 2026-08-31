"use client"

import { useState } from "react"
import { useQuery } from "@tanstack/react-query"
import { MetricCard, Panel } from "@/components/metric-card"
import { RatingDistributionChart, ADASTimelineChart, RankedBarChart } from "@/components/overview-charts"
import { fmtNum, fmtStars, fmtPct, ratingColor, pctColor, CHART_COLORS } from "@/lib/format"
import type { Overview, Facets } from "@/lib/types"
import { Activity, ShieldCheck, AlertTriangle, Car, Gauge, Eye, X } from "lucide-react"

export function OverviewDashboard() {
  const [make, setMake] = useState("")
  const [bodyStyle, setBodyStyle] = useState("")
  const [year, setYear] = useState("")

  const params = new URLSearchParams()
  if (make) params.set("make", make)
  if (bodyStyle) params.set("bodyStyle", bodyStyle)
  if (year) params.set("year", year)
  const qs = params.toString()

  const { data: facets } = useQuery<Facets>({
    queryKey: ["facets"],
    queryFn: () => fetch("/api/facets").then(r => r.json()),
    staleTime: 300_000,
  })

  const { data, isLoading, isFetching } = useQuery<Overview>({
    queryKey: ["overview", make, bodyStyle, year],
    queryFn: () => fetch(`/api/overview${qs ? `?${qs}` : ""}`).then(r => r.json()),
    staleTime: 60_000,
    placeholderData: (prev: any) => prev,
  })

  const k = data?.kpis
  const hasFilters = make || bodyStyle || year
  const filterLabel = [make, bodyStyle, year && `MY ${year}`].filter(Boolean).join(" / ") || "All Vehicles"

  return (
    <div className="space-y-4">
      {/* Filter Bar */}
      <div className="flex flex-wrap items-center gap-2 rounded-lg border border-border bg-card px-4 py-3">
        <select value={make} onChange={e => setMake(e.target.value)}
          className="rounded-md border border-input bg-background px-3 py-1.5 text-sm">
          <option value="">All Makes</option>
          {facets?.makes.map(m => <option key={m} value={m}>{m}</option>)}
        </select>
        <select value={bodyStyle} onChange={e => setBodyStyle(e.target.value)}
          className="rounded-md border border-input bg-background px-3 py-1.5 text-sm">
          <option value="">All Body Styles</option>
          {facets?.bodyStyles.map(b => <option key={b} value={b}>{b}</option>)}
        </select>
        <select value={year} onChange={e => setYear(e.target.value)}
          className="rounded-md border border-input bg-background px-3 py-1.5 text-sm">
          <option value="">All Years</option>
          {facets?.years.map(y => <option key={y} value={String(y)}>{y}</option>)}
        </select>
        {hasFilters && (
          <button onClick={() => { setMake(""); setBodyStyle(""); setYear("") }}
            className="flex items-center gap-1 rounded-md border border-input px-2 py-1.5 text-xs text-muted-foreground hover:text-foreground">
            <X size={12} /> Reset
          </button>
        )}
        {isFetching && <span className="text-xs text-muted-foreground ml-auto">Updating...</span>}
        {!isFetching && hasFilters && <span className="text-xs text-muted-foreground ml-auto">Showing: {filterLabel}</span>}
      </div>

      {/* Row 1: Primary KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3">
        <MetricCard label="Vehicles Tested" value={fmtNum(k?.totalVehicles)} sub={`${fmtNum(k?.totalMakers)} makers`} icon={<Car size={16} />} loading={isLoading} />
        <MetricCard label="Avg Overall Rating" value={fmtStars(k?.avgOverall)} sub="out of 5 stars" accent={k?.avgOverall != null ? ratingColor(k.avgOverall) : undefined} icon={<ShieldCheck size={16} />} loading={isLoading} />
        <MetricCard label="5-Star Vehicles" value={fmtNum(k?.fiveStarCount)} sub={`${fmtPct(k?.fiveStarPct)} of rated`} accent="var(--status-5star)" icon={<Activity size={16} />} loading={isLoading} />
        <MetricCard label="High Rollover Risk" value={fmtNum(k?.highRolloverRisk)} sub="probability > 0.15" accent={k?.highRolloverRisk && k.highRolloverRisk > 0 ? "var(--status-high-risk)" : undefined} icon={<AlertTriangle size={16} />} loading={isLoading} />
      </div>

      {/* Row 2: Secondary KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3">
        <MetricCard label="Avg Frontal Rating" value={fmtStars(k?.avgFrontal)} sub="head-on collision" accent={k?.avgFrontal != null ? ratingColor(k.avgFrontal) : undefined} loading={isLoading} />
        <MetricCard label="Avg Side Rating" value={fmtStars(k?.avgSide)} sub="side-impact" accent={k?.avgSide != null ? ratingColor(k.avgSide) : undefined} loading={isLoading} />
        <MetricCard label="Auto-Brake Adoption" value={fmtPct(k?.avgCIB)} sub="crash imminent braking" accent={k?.avgCIB != null ? pctColor(k.avgCIB) : undefined} icon={<Gauge size={16} />} loading={isLoading} />
        <MetricCard label="Fwd Collision Warning" value={fmtPct(k?.avgFCW)} sub="FCW equipped" accent={k?.avgFCW != null ? pctColor(k.avgFCW) : undefined} icon={<Eye size={16} />} loading={isLoading} />
      </div>

      {/* Row 3: 2/3 + 1/3 split */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
        <Panel title="ADAS Adoption Over Time" description="Safety technology penetration by model year (2010+)" className="xl:col-span-2">
          {data ? <ADASTimelineChart data={data.adasTimeline} /> : <EmptyState loading={isLoading} />}
        </Panel>
        <Panel title="Star Rating Distribution" description="Overall crash test rating breakdown">
          {data ? <RatingDistributionChart data={data.ratingDistribution} /> : <EmptyState loading={isLoading} />}
        </Panel>
      </div>

      {/* Row 4: 1/2 + 1/2 split */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <Panel title="Top Makers by Overall Safety" description="Average star rating">
          {data ? <RankedBarChart data={data.topMakersByRating} labelKey="make" valueKey="avgOverall" color={CHART_COLORS[0]} /> : <EmptyState loading={isLoading} />}
        </Panel>
        <Panel title="Safety Rating by Body Style" description="Average overall stars by body type">
          {data ? <RankedBarChart data={data.ratingByBodyStyle} labelKey="bodyStyle" valueKey="avgOverall" color={CHART_COLORS[2]} /> : <EmptyState loading={isLoading} />}
        </Panel>
      </div>

      {/* Row 5: 1/3 + 1/3 + 1/3 split */}
      <div className="grid grid-cols-1 xl:grid-cols-3 gap-4">
        <Panel title="Top Makers by Auto-Brake" description="CIB adoption rate">
          {data ? <RankedBarChart data={data.topMakersByADAS} labelKey="make" valueKey="pctCIB" color={CHART_COLORS[2]} unit="%" height={280} /> : <EmptyState loading={isLoading} />}
        </Panel>
        <Panel title="Top Makers by Blind Spot Detection" description="BSD adoption rate">
          {data ? <RankedBarChart data={data.topMakersByADAS} labelKey="make" valueKey="pctBSD" color={CHART_COLORS[3]} unit="%" height={280} /> : <EmptyState loading={isLoading} />}
        </Panel>
        <Panel title="Vehicles by Body Style" description="Distribution of tested vehicles">
          {data ? <RankedBarChart data={data.vehiclesByBodyStyle} labelKey="bodyStyle" valueKey="count" color={CHART_COLORS[1]} height={280} /> : <EmptyState loading={isLoading} />}
        </Panel>
      </div>

      <p className="text-xs text-muted-foreground text-center pb-2">
        Source: NHTSA SaferCar Data | National Highway Traffic Safety Administration
      </p>
    </div>
  )
}

function EmptyState({ loading }: { loading: boolean }) {
  if (loading) return <div className="flex h-[220px] items-center justify-center text-xs text-muted-foreground">Loading...</div>
  return <div className="flex h-[220px] items-center justify-center text-xs text-muted-foreground">No data</div>
}
