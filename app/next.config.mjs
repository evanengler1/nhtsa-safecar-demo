import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  outputFileTracingRoot: __dirname,
  turbopack: { root: __dirname },
  typescript: { ignoreBuildErrors: true },
  images: { unoptimized: true },
}

export default nextConfig
