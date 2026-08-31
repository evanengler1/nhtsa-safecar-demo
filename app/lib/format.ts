export const RATING_VAR: Record<string, string> = {
  "5star": "var(--status-5star)",
  "4star": "var(--status-4star)",
  "3star": "var(--status-3star)",
  "low": "var(--status-low)",
  "high-risk": "var(--status-high-risk)",
  "good": "var(--status-good)",
  "neutral": "var(--status-neutral)",
}

export const CHART_COLORS = [
  "var(--chart-1)", "var(--chart-2)", "var(--chart-3)",
  "var(--chart-4)", "var(--chart-5)", "var(--chart-6)",
]

export function ratingColor(stars: number | null): string {
  if (stars == null) return RATING_VAR.neutral
  if (stars >= 4.5) return RATING_VAR["5star"]
  if (stars >= 3.5) return RATING_VAR["4star"]
  if (stars >= 2.5) return RATING_VAR["3star"]
  return RATING_VAR.low
}

export function pctColor(pct: number | null): string {
  if (pct == null) return RATING_VAR.neutral
  if (pct >= 70) return RATING_VAR.good
  if (pct >= 40) return RATING_VAR["3star"]
  return RATING_VAR.low
}

export function fmtNum(n: number | null | undefined): string {
  if (n == null) return "--"
  return n.toLocaleString()
}

export function fmtPct(n: number | null | undefined): string {
  if (n == null) return "--"
  return `${n.toFixed(1)}%`
}

export function fmtStars(n: number | null | undefined): string {
  if (n == null) return "--"
  return n.toFixed(2)
}
