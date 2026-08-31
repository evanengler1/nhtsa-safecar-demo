import { headers } from "next/headers"
import fs from "fs"
import snowflake from "snowflake-sdk"

snowflake.configure({ logLevel: "ERROR" })

const SPCS_TOKEN_PATH = "/snowflake/session/token"
const DB = "NHTSA_SAFECAR_DEMO"
const SCHEMA = "SAFETY_DATA"

function readToken(): string | null {
  try { return fs.readFileSync(SPCS_TOKEN_PATH, "utf8").trim() } catch { return null }
}

function getCallerToken(): string | null {
  try {
    const h = headers()
    return (h as any).get?.("sf-context-current-user-token") ?? null
  } catch { return null }
}

function createConnection(): any {
  const token = readToken()
  if (!token) {
    return snowflake.createConnection({
      account: process.env.SNOWFLAKE_ACCOUNT || "",
      username: process.env.SNOWFLAKE_USER || "",
      password: process.env.SNOWFLAKE_PASSWORD || "",
      database: DB,
      schema: SCHEMA,
      warehouse: process.env.SNOWFLAKE_WAREHOUSE || "NHTSA_SAFECAR_WH",
    })
  }

  const callerToken = getCallerToken()
  const fullToken = callerToken ? `${token}.${callerToken}` : token

  return snowflake.createConnection({
    account: process.env.SNOWFLAKE_ACCOUNT || "",
    host: process.env.SNOWFLAKE_HOST || "",
    authenticator: "OAUTH",
    token: fullToken,
    database: DB,
    schema: SCHEMA,
  })
}

export async function querySnowflake<T = Record<string, unknown>>(sql: string): Promise<T[]> {
  const conn = createConnection()
  return new Promise((resolve, reject) => {
    conn.connect((err: any) => {
      if (err) { console.error("[snowflake] connect error:", err.message); return reject(err) }
      conn.execute({
        sqlText: sql,
        complete: (err: any, _stmt: any, rows: any[]) => {
          conn.destroy()
          if (err) { console.error("[snowflake] query error:", err.message, sql.substring(0, 100)); return reject(err) }
          resolve(rows as T[])
        },
      })
    })
  })
}

export function toNum(v: unknown): number | null {
  if (v == null) return null
  const n = Number(v)
  return isNaN(n) ? null : n
}
