const LOCAL_URL = "http://localhost:3000";

function parseHttpUrl(value: string) {
  const url = new URL(value);

  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error("NEXT_PUBLIC_APP_URL must use http or https.");
  }

  return url;
}

export function getSiteUrl() {
  if (process.env.NEXT_PUBLIC_APP_URL) {
    return parseHttpUrl(process.env.NEXT_PUBLIC_APP_URL);
  }

  const vercelHost = process.env.VERCEL_PROJECT_PRODUCTION_URL ?? process.env.VERCEL_URL;
  return parseHttpUrl(vercelHost ? `https://${vercelHost}` : LOCAL_URL);
}
