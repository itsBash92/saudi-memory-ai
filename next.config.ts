import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  // Type checking runs explicitly in `npm run build` before Next.js compiles.
  // Keeping it outside Next's worker makes local and CI behavior deterministic.
  typescript: {
    ignoreBuildErrors: true,
  },
};

export default nextConfig;
