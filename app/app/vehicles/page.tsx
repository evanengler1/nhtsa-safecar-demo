import { Suspense } from "react"
import { VehicleGrid } from "@/components/vehicle-grid"

export default function VehiclesPage() {
  return (
    <main className="mx-auto w-full max-w-[1600px] px-4 py-5">
      <div className="mb-4">
        <h1 className="text-lg font-semibold tracking-tight">Vehicle Search</h1>
        <p className="text-sm text-muted-foreground">Search and filter across 17,000+ tested vehicles by make, model, year, and safety features</p>
      </div>
      <Suspense fallback={<div className="text-sm text-muted-foreground">Loading...</div>}>
        <VehicleGrid />
      </Suspense>
    </main>
  )
}
