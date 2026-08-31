import type { Metadata } from "next"
import "@/app/globals.css"
import { ThemeProvider } from "@/components/theme-provider"
import { QueryProvider } from "@/components/query-provider"
import { AppHeader } from "@/components/app-header"

export const metadata: Metadata = {
  title: "NHTSA Fleet Safety Dashboard",
  description: "Vehicle safety ratings, ADAS adoption, and crash test analysis",
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body>
        <ThemeProvider attribute="class" defaultTheme="light" enableSystem disableTransitionOnChange>
          <QueryProvider>
            <AppHeader />
            {children}
          </QueryProvider>
        </ThemeProvider>
      </body>
    </html>
  )
}
