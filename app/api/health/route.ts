import { NextResponse } from "next/server";

export function GET() {
  return NextResponse.json({
    status: "ok",
    service: "saudi-memory-ai",
    version: "0.1.0",
    timestamp: new Date().toISOString(),
  });
}
