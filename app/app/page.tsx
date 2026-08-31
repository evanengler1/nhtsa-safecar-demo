import { OverviewDashboard } from "@/components/overview-dashboard"

export default function Home() {
  return (
    <main className="mx-auto w-full max-w-[1600px] px-4 py-5">
      <div className="mb-4">
        <h1 className="text-lg font-semibold tracking-tight">Fleet Safety Overview</h1>
        <p className="text-sm text-muted-foreground">Crash test ratings and safety technology adoption across all tested vehicles</p>
      </div>
      <OverviewDashboard />
    </main>
  )
}
