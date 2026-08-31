import { NextRequest } from "next/server"
import { querySnowflake, toNum } from "@/lib/snowflake"
import type { Overview } from "@/lib/types"

const T = "NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_SAFERCAR"

function esc(v: string): string { return v.replace(/'/g, "''") }

export async function GET(req: NextRequest) {
  try {
    const p = req.nextUrl.searchParams
    const make = p.get("make")
    const bodyStyle = p.get("bodyStyle")
    const year = p.get("year")

    const where: string[] = ["MAKE IS NOT NULL"]
    if (make) where.push(`MAKE = '${esc(make)}'`)
    if (bodyStyle) where.push(`BODY_STYLE = '${esc(bodyStyle)}'`)
    if (year) where.push(`MODEL_YR = ${parseInt(year)}`)
    const W = where.join(" AND ")

    const minGroup = make ? 1 : 10
    const minBodyGroup = bodyStyle ? 1 : 20

    const [kpiRows, ratingDist, adasTimeline, topMakers, topADAS, byBodyStyle, bodyCount] = await Promise.all([
      querySnowflake(`
        SELECT
          COUNT(*) AS TOTAL,
          COUNT(DISTINCT MAKE) AS MAKERS,
          ROUND(AVG(TRY_TO_NUMBER(OVERALL_STARS)), 2) AS AVG_OVERALL,
          ROUND(AVG(TRY_TO_NUMBER(OVERALL_FRNT_STARS)), 2) AS AVG_FRONTAL,
          ROUND(AVG(TRY_TO_NUMBER(OVERALL_SIDE_STARS)), 2) AS AVG_SIDE,
          ROUND(AVG(TRY_TO_NUMBER(ROLLOVER_STARS)), 2) AS AVG_ROLLOVER,
          COUNT_IF(TRY_TO_NUMBER(OVERALL_STARS) = 5) AS FIVE_STAR,
          ROUND(100.0 * COUNT_IF(TRY_TO_NUMBER(OVERALL_STARS) = 5) / NULLIF(COUNT_IF(OVERALL_STARS IS NOT NULL), 0), 1) AS FIVE_STAR_PCT,
          COUNT_IF(ROLLOVER_POSSIBILITY > 0.15) AS HIGH_ROLLOVER,
          ROUND(100.0 * COUNT_IF(CRASH_IMMINENT_BRAKE IS NOT NULL AND TRIM(CRASH_IMMINENT_BRAKE) != '') / NULLIF(COUNT(*), 0), 1) AS AVG_CIB,
          ROUND(100.0 * COUNT_IF(FRNT_COLLISION_WARNING IS NOT NULL AND TRIM(FRNT_COLLISION_WARNING) != '') / NULLIF(COUNT(*), 0), 1) AS AVG_FCW,
          ROUND(100.0 * COUNT_IF(BLIND_SPOT_DETECTION IS NOT NULL AND TRIM(BLIND_SPOT_DETECTION) != '') / NULLIF(COUNT(*), 0), 1) AS AVG_BSD
        FROM ${T} WHERE ${W}
      `),
      querySnowflake(`
        SELECT TRY_TO_NUMBER(OVERALL_STARS) AS STARS, COUNT(*) AS CNT
        FROM ${T} WHERE OVERALL_STARS IS NOT NULL AND ${W}
        GROUP BY STARS ORDER BY STARS
      `),
      querySnowflake(`
        SELECT MODEL_YR AS YR,
          ROUND(100.0 * COUNT_IF(CRASH_IMMINENT_BRAKE IS NOT NULL AND TRIM(CRASH_IMMINENT_BRAKE) != '') / NULLIF(COUNT(*), 0), 1) AS PCT_CIB,
          ROUND(100.0 * COUNT_IF(FRNT_COLLISION_WARNING IS NOT NULL AND TRIM(FRNT_COLLISION_WARNING) != '') / NULLIF(COUNT(*), 0), 1) AS PCT_FCW,
          ROUND(100.0 * COUNT_IF(BLIND_SPOT_DETECTION IS NOT NULL AND TRIM(BLIND_SPOT_DETECTION) != '') / NULLIF(COUNT(*), 0), 1) AS PCT_BSD,
          ROUND(100.0 * COUNT_IF(LANE_DEPARTURE_WARNING IS NOT NULL AND TRIM(LANE_DEPARTURE_WARNING) != '') / NULLIF(COUNT(*), 0), 1) AS PCT_LDW
        FROM ${T} WHERE MODEL_YR >= 2010 AND ${W}
        GROUP BY MODEL_YR HAVING COUNT(*) >= 3 ORDER BY MODEL_YR
      `),
      querySnowflake(`
        SELECT MAKE, ROUND(AVG(TRY_TO_NUMBER(OVERALL_STARS)), 2) AS AVG_OVERALL, COUNT(*) AS CNT
        FROM ${T} WHERE OVERALL_STARS IS NOT NULL AND ${W}
        GROUP BY MAKE HAVING COUNT(*) >= ${minGroup}
        ORDER BY AVG_OVERALL DESC NULLS LAST LIMIT 15
      `),
      querySnowflake(`
        SELECT MAKE,
          ROUND(100.0 * COUNT_IF(CRASH_IMMINENT_BRAKE IS NOT NULL AND TRIM(CRASH_IMMINENT_BRAKE) != '') / NULLIF(COUNT(*), 0), 1) AS PCT_CIB,
          ROUND(100.0 * COUNT_IF(FRNT_COLLISION_WARNING IS NOT NULL AND TRIM(FRNT_COLLISION_WARNING) != '') / NULLIF(COUNT(*), 0), 1) AS PCT_FCW,
          ROUND(100.0 * COUNT_IF(BLIND_SPOT_DETECTION IS NOT NULL AND TRIM(BLIND_SPOT_DETECTION) != '') / NULLIF(COUNT(*), 0), 1) AS PCT_BSD
        FROM ${T} WHERE ${W}
        GROUP BY MAKE HAVING COUNT(*) >= ${minGroup}
        ORDER BY PCT_CIB DESC NULLS LAST LIMIT 15
      `),
      querySnowflake(`
        SELECT BODY_STYLE, ROUND(AVG(TRY_TO_NUMBER(OVERALL_STARS)), 2) AS AVG_OVERALL, COUNT(*) AS CNT
        FROM ${T} WHERE BODY_STYLE IS NOT NULL AND OVERALL_STARS IS NOT NULL AND ${W}
        GROUP BY BODY_STYLE HAVING COUNT(*) >= ${minBodyGroup}
        ORDER BY AVG_OVERALL DESC NULLS LAST LIMIT 10
      `),
      querySnowflake(`
        SELECT BODY_STYLE, COUNT(*) AS CNT
        FROM ${T} WHERE BODY_STYLE IS NOT NULL AND ${W}
        GROUP BY BODY_STYLE HAVING COUNT(*) >= ${minBodyGroup}
        ORDER BY CNT DESC LIMIT 10
      `),
    ])

    const k = kpiRows[0] as any
    const overview: Overview = {
      kpis: {
        totalVehicles: toNum(k.TOTAL) ?? 0,
        totalMakers: toNum(k.MAKERS) ?? 0,
        avgOverall: toNum(k.AVG_OVERALL),
        avgFrontal: toNum(k.AVG_FRONTAL),
        avgSide: toNum(k.AVG_SIDE),
        avgRollover: toNum(k.AVG_ROLLOVER),
        fiveStarCount: toNum(k.FIVE_STAR) ?? 0,
        fiveStarPct: toNum(k.FIVE_STAR_PCT) ?? 0,
        highRolloverRisk: toNum(k.HIGH_ROLLOVER) ?? 0,
        avgCIB: toNum(k.AVG_CIB),
        avgFCW: toNum(k.AVG_FCW),
        avgBSD: toNum(k.AVG_BSD),
      },
      ratingDistribution: (ratingDist as any[]).map(r => ({ stars: toNum(r.STARS) ?? 0, count: toNum(r.CNT) ?? 0 })),
      adasTimeline: (adasTimeline as any[]).map(r => ({
        year: toNum(r.YR) ?? 0, pctCIB: toNum(r.PCT_CIB) ?? 0, pctFCW: toNum(r.PCT_FCW) ?? 0,
        pctBSD: toNum(r.PCT_BSD) ?? 0, pctLDW: toNum(r.PCT_LDW) ?? 0,
      })),
      topMakersByRating: (topMakers as any[]).map(r => ({ make: r.MAKE, avgOverall: toNum(r.AVG_OVERALL) ?? 0, vehicleCount: toNum(r.CNT) ?? 0 })),
      topMakersByADAS: (topADAS as any[]).map(r => ({ make: r.MAKE, pctCIB: toNum(r.PCT_CIB) ?? 0, pctFCW: toNum(r.PCT_FCW) ?? 0, pctBSD: toNum(r.PCT_BSD) ?? 0 })),
      ratingByBodyStyle: (byBodyStyle as any[]).map(r => ({ bodyStyle: r.BODY_STYLE, avgOverall: toNum(r.AVG_OVERALL) ?? 0, count: toNum(r.CNT) ?? 0 })),
      vehiclesByBodyStyle: (bodyCount as any[]).map(r => ({ bodyStyle: r.BODY_STYLE, count: toNum(r.CNT) ?? 0 })),
    }

    return Response.json(overview)
  } catch (err: any) {
    console.error("[api/overview]", err.message)
    return Response.json({ error: err.message }, { status: 500 })
  }
}
