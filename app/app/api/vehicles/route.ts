import { NextRequest } from "next/server"
import { querySnowflake, toNum } from "@/lib/snowflake"
import type { Vehicle } from "@/lib/types"

const T = "NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_SAFERCAR"

export async function GET(req: NextRequest) {
  try {
    const p = req.nextUrl.searchParams
    const make = p.get("make")
    const year = p.get("year")
    const bodyStyle = p.get("bodyStyle")
    const search = p.get("q")
    const sortCol = p.get("sort") || "OVERALL_STARS"
    const sortDir = p.get("dir") === "asc" ? "ASC" : "DESC"
    const limit = Math.min(Number(p.get("limit")) || 50, 250)
    const offset = Number(p.get("offset")) || 0

    const VALID_SORT = ["MAKE", "MODEL", "MODEL_YR", "OVERALL_STARS", "OVERALL_FRNT_STARS", "OVERALL_SIDE_STARS", "ROLLOVER_STARS", "ROLLOVER_POSSIBILITY"]
    const safeSort = VALID_SORT.includes(sortCol) ? sortCol : "OVERALL_STARS"

    const where: string[] = ["MAKE IS NOT NULL"]
    if (make) where.push(`MAKE = '${make.replace(/'/g, "''")}'`)
    if (year) where.push(`MODEL_YR = ${parseInt(year)}`)
    if (bodyStyle) where.push(`BODY_STYLE = '${bodyStyle.replace(/'/g, "''")}'`)
    if (search) where.push(`(MAKE ILIKE '%${search.replace(/'/g, "''")}%' OR MODEL ILIKE '%${search.replace(/'/g, "''")}%')`)

    const whereClause = where.join(" AND ")

    const [rows, countRows] = await Promise.all([
      querySnowflake(`
        SELECT MAKE, MODEL, MODEL_YR, BODY_STYLE, DRIVE_TRAIN,
          TRY_TO_NUMBER(OVERALL_STARS) AS OVERALL_STARS,
          TRY_TO_NUMBER(OVERALL_FRNT_STARS) AS FRONTAL_STARS,
          TRY_TO_NUMBER(OVERALL_SIDE_STARS) AS SIDE_STARS,
          TRY_TO_NUMBER(ROLLOVER_STARS) AS ROLLOVER_STARS,
          ROLLOVER_POSSIBILITY,
          CASE WHEN FRNT_COLLISION_WARNING IS NOT NULL AND TRIM(FRNT_COLLISION_WARNING) != '' THEN TRUE ELSE FALSE END AS HAS_FCW,
          CASE WHEN CRASH_IMMINENT_BRAKE IS NOT NULL AND TRIM(CRASH_IMMINENT_BRAKE) != '' THEN TRUE ELSE FALSE END AS HAS_CIB,
          CASE WHEN LANE_DEPARTURE_WARNING IS NOT NULL AND TRIM(LANE_DEPARTURE_WARNING) != '' THEN TRUE ELSE FALSE END AS HAS_LDW,
          CASE WHEN BLIND_SPOT_DETECTION IS NOT NULL AND TRIM(BLIND_SPOT_DETECTION) != '' THEN TRUE ELSE FALSE END AS HAS_BSD,
          CASE WHEN NHTSA_ESC IS NOT NULL AND TRIM(NHTSA_ESC) != '' THEN TRUE ELSE FALSE END AS HAS_ESC
        FROM ${T}
        WHERE ${whereClause}
        ORDER BY ${safeSort} ${sortDir} NULLS LAST
        LIMIT ${limit} OFFSET ${offset}
      `),
      querySnowflake(`SELECT COUNT(*) AS CNT FROM ${T} WHERE ${whereClause}`),
    ])

    const vehicles: Vehicle[] = (rows as any[]).map(r => ({
      make: r.MAKE,
      model: r.MODEL,
      modelYr: toNum(r.MODEL_YR) ?? 0,
      bodyStyle: r.BODY_STYLE,
      driveTrain: r.DRIVE_TRAIN,
      overallStars: toNum(r.OVERALL_STARS),
      frontalStars: toNum(r.FRONTAL_STARS),
      sideStars: toNum(r.SIDE_STARS),
      rolloverStars: toNum(r.ROLLOVER_STARS),
      rolloverPossibility: toNum(r.ROLLOVER_POSSIBILITY),
      hasFCW: r.HAS_FCW === true,
      hasCIB: r.HAS_CIB === true,
      hasLDW: r.HAS_LDW === true,
      hasBSD: r.HAS_BSD === true,
      hasESC: r.HAS_ESC === true,
    }))

    const total = toNum((countRows as any[])[0]?.CNT) ?? 0

    return Response.json({ vehicles, total, limit, offset })
  } catch (err: any) {
    return Response.json({ error: err.message }, { status: 500 })
  }
}
