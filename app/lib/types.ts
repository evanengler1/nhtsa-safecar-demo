export interface OverviewKPIs {
  totalVehicles: number
  totalMakers: number
  avgOverall: number | null
  avgFrontal: number | null
  avgSide: number | null
  avgRollover: number | null
  fiveStarCount: number
  fiveStarPct: number
  highRolloverRisk: number
  avgCIB: number | null
  avgFCW: number | null
  avgBSD: number | null
}

export interface Overview {
  kpis: OverviewKPIs
  ratingDistribution: { stars: number; count: number }[]
  adasTimeline: { year: number; pctCIB: number; pctFCW: number; pctBSD: number; pctLDW: number }[]
  topMakersByRating: { make: string; avgOverall: number; vehicleCount: number }[]
  topMakersByADAS: { make: string; pctCIB: number; pctFCW: number; pctBSD: number }[]
  ratingByBodyStyle: { bodyStyle: string; avgOverall: number; count: number }[]
  vehiclesByBodyStyle: { bodyStyle: string; count: number }[]
}

export interface Vehicle {
  make: string
  model: string
  modelYr: number
  bodyStyle: string | null
  driveTrain: string | null
  overallStars: number | null
  frontalStars: number | null
  sideStars: number | null
  rolloverStars: number | null
  rolloverPossibility: number | null
  hasFCW: boolean
  hasCIB: boolean
  hasLDW: boolean
  hasBSD: boolean
  hasESC: boolean
}

export interface Facets {
  makes: string[]
  bodyStyles: string[]
  years: number[]
}
