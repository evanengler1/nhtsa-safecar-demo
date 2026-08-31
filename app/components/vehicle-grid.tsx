"use client"

import { useState, useEffect } from "react"
import { useQuery } from "@tanstack/react-query"
import { useSearchParams } from "next/navigation"
import { Skeleton } from "@/components/ui/skeleton"
import { Search, ChevronUp, ChevronDown } from "lucide-react"
import type { Vehicle, Facets } from "@/lib/types"

function StarCell({ val }: { val: number | null }) {
  if (val == null) return <span className="text-muted-foreground">--</span>
  const color = val >= 4.5 ? "text-green-600" : val >= 3 ? "text-yellow-600" : "text-red-600"
  return <span className={`font-medium ${color}`}>{val}</span>
}

function BoolCell({ val }: { val: boolean }) {
  return val
    ? <span className="text-green-600 text-xs font-medium">Yes</span>
    : <span className="text-muted-foreground text-xs">No</span>
}

export function VehicleGrid() {
  const searchParams = useSearchParams()
  const [make, setMake] = useState(searchParams.get("make") || "")
  const [year, setYear] = useState(searchParams.get("year") || "")
  const [bodyStyle, setBodyStyle] = useState(searchParams.get("bodyStyle") || "")
  const [q, setQ] = useState("")
  const [sort, setSort] = useState("OVERALL_STARS")
  const [dir, setDir] = useState<"desc" | "asc">("desc")
  const [page, setPage] = useState(0)
  const limit = 50

  const { data: facets } = useQuery<Facets>({
    queryKey: ["facets"],
    queryFn: () => fetch("/api/facets").then(r => r.json()),
    staleTime: 300_000,
  })

  const params = new URLSearchParams()
  if (make) params.set("make", make)
  if (year) params.set("year", year)
  if (bodyStyle) params.set("bodyStyle", bodyStyle)
  if (q) params.set("q", q)
  params.set("sort", sort)
  params.set("dir", dir)
  params.set("limit", String(limit))
  params.set("offset", String(page * limit))

  const { data, isLoading, isFetching } = useQuery<{ vehicles: Vehicle[]; total: number }>({
    queryKey: ["vehicles", make, year, bodyStyle, q, sort, dir, page],
    queryFn: () => fetch(`/api/vehicles?${params}`).then(r => r.json()),
    placeholderData: (prev: any) => prev,
  })

  const vehicles = data?.vehicles ?? []
  const total = data?.total ?? 0
  const totalPages = Math.ceil(total / limit)

  const handleSort = (col: string) => {
    if (sort === col) { setDir(d => d === "desc" ? "asc" : "desc") }
    else { setSort(col); setDir("desc") }
    setPage(0)
  }

  useEffect(() => { setPage(0) }, [make, year, bodyStyle, q])

  const SortIcon = ({ col }: { col: string }) => {
    if (sort !== col) return <span className="text-gray-300 ml-0.5">&#8597;</span>
    return dir === "desc" ? <ChevronDown size={12} className="inline ml-0.5" /> : <ChevronUp size={12} className="inline ml-0.5" />
  }

  const cols: { key: string; label: string; sortCol?: string; align?: "right" }[] = [
    { key: "make", label: "Make", sortCol: "MAKE" },
    { key: "model", label: "Model", sortCol: "MODEL" },
    { key: "modelYr", label: "Year", sortCol: "MODEL_YR", align: "right" },
    { key: "bodyStyle", label: "Body" },
    { key: "overallStars", label: "Overall", sortCol: "OVERALL_STARS", align: "right" },
    { key: "frontalStars", label: "Frontal", sortCol: "OVERALL_FRNT_STARS", align: "right" },
    { key: "sideStars", label: "Side", sortCol: "OVERALL_SIDE_STARS", align: "right" },
    { key: "rolloverStars", label: "Rollover", sortCol: "ROLLOVER_STARS", align: "right" },
    { key: "hasCIB", label: "Auto-Brake" },
    { key: "hasFCW", label: "FCW" },
    { key: "hasBSD", label: "Blind Spot" },
  ]

  return (
    <div className="space-y-3">
      {/* Filter Bar */}
      <div className="flex flex-wrap gap-2 items-end">
        <div className="relative flex-1 min-w-[200px]">
          <Search size={14} className="absolute left-2.5 top-2.5 text-muted-foreground" />
          <input
            type="text" placeholder="Search make or model..."
            value={q} onChange={e => setQ(e.target.value)}
            className="w-full rounded-md border border-border bg-background pl-8 pr-3 py-2 text-sm"
          />
        </div>
        <select value={make} onChange={e => setMake(e.target.value)} className="rounded-md border border-border bg-background px-3 py-2 text-sm">
          <option value="">All Makes</option>
          {facets?.makes.map(m => <option key={m} value={m}>{m}</option>)}
        </select>
        <select value={year} onChange={e => setYear(e.target.value)} className="rounded-md border border-border bg-background px-3 py-2 text-sm">
          <option value="">All Years</option>
          {facets?.years.map(y => <option key={y} value={String(y)}>{y}</option>)}
        </select>
        <select value={bodyStyle} onChange={e => setBodyStyle(e.target.value)} className="rounded-md border border-border bg-background px-3 py-2 text-sm">
          <option value="">All Body Styles</option>
          {facets?.bodyStyles.map(b => <option key={b} value={b}>{b}</option>)}
        </select>
        {(make || year || bodyStyle || q) && (
          <button onClick={() => { setMake(""); setYear(""); setBodyStyle(""); setQ("") }}
            className="text-xs text-muted-foreground hover:text-foreground px-2 py-2">
            Reset
          </button>
        )}
      </div>

      {/* Results count */}
      <div className="flex items-center justify-between text-xs text-muted-foreground">
        <span>{isFetching ? "Loading..." : `${total.toLocaleString()} vehicles`}</span>
        <span>Page {page + 1} of {totalPages || 1}</span>
      </div>

      {/* Table */}
      <div className="rounded-lg border border-border bg-card overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="border-b border-border bg-muted/50">
            <tr>
              {cols.map(c => (
                <th key={c.key}
                  className={`px-3 py-2.5 text-xs font-medium uppercase tracking-wide text-muted-foreground whitespace-nowrap ${c.sortCol ? "cursor-pointer hover:text-foreground" : ""} ${c.align === "right" ? "text-right" : "text-left"}`}
                  onClick={c.sortCol ? () => handleSort(c.sortCol!) : undefined}
                >
                  {c.label}{c.sortCol && <SortIcon col={c.sortCol} />}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-border">
            {isLoading && !vehicles.length ? (
              Array.from({ length: 12 }).map((_, i) => (
                <tr key={i}><td colSpan={cols.length} className="px-3 py-2.5"><Skeleton className="h-4 w-full" /></td></tr>
              ))
            ) : vehicles.map((v, i) => (
              <tr key={`${v.make}-${v.model}-${v.modelYr}-${i}`} className="hover:bg-muted/30 transition-colors">
                <td className="px-3 py-2 font-medium">{v.make}</td>
                <td className="px-3 py-2">{v.model}</td>
                <td className="px-3 py-2 text-right nums">{v.modelYr}</td>
                <td className="px-3 py-2 text-xs">{v.bodyStyle ?? "--"}</td>
                <td className="px-3 py-2 text-right"><StarCell val={v.overallStars} /></td>
                <td className="px-3 py-2 text-right"><StarCell val={v.frontalStars} /></td>
                <td className="px-3 py-2 text-right"><StarCell val={v.sideStars} /></td>
                <td className="px-3 py-2 text-right"><StarCell val={v.rolloverStars} /></td>
                <td className="px-3 py-2 text-center"><BoolCell val={v.hasCIB} /></td>
                <td className="px-3 py-2 text-center"><BoolCell val={v.hasFCW} /></td>
                <td className="px-3 py-2 text-center"><BoolCell val={v.hasBSD} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-center gap-2 text-sm">
          <button onClick={() => setPage(p => Math.max(0, p - 1))} disabled={page === 0}
            className="px-3 py-1 rounded border border-border disabled:opacity-30">&lt; Prev</button>
          <span className="text-xs text-muted-foreground">{page + 1} / {totalPages}</span>
          <button onClick={() => setPage(p => Math.min(totalPages - 1, p + 1))} disabled={page >= totalPages - 1}
            className="px-3 py-1 rounded border border-border disabled:opacity-30">Next &gt;</button>
        </div>
      )}
    </div>
  )
}
