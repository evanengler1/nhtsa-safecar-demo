import { querySnowflake } from "@/lib/snowflake"
import type { Facets } from "@/lib/types"

const T = "NHTSA_SAFECAR_DEMO.SAFETY_DATA.RAW_SAFERCAR"

export async function GET() {
  try {
    const [makes, styles, years] = await Promise.all([
      querySnowflake(`SELECT DISTINCT MAKE FROM ${T} WHERE MAKE IS NOT NULL ORDER BY MAKE`),
      querySnowflake(`SELECT DISTINCT BODY_STYLE FROM ${T} WHERE BODY_STYLE IS NOT NULL ORDER BY BODY_STYLE`),
      querySnowflake(`SELECT DISTINCT MODEL_YR FROM ${T} WHERE MODEL_YR IS NOT NULL ORDER BY MODEL_YR DESC`),
    ])

    const facets: Facets = {
      makes: (makes as any[]).map(r => r.MAKE),
      bodyStyles: (styles as any[]).map(r => r.BODY_STYLE),
      years: (years as any[]).map(r => Number(r.MODEL_YR)),
    }
    return Response.json(facets)
  } catch (err: any) {
    return Response.json({ error: err.message }, { status: 500 })
  }
}
