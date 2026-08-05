import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(process.env.NEXT_PUBLIC_APP_URL ?? "http://localhost:3000"),
  title: {
    default: "Saudi Memory AI | Every Place Holds a Memory",
    template: "%s | Saudi Memory AI",
  },
  description:
    "An intelligent platform for preserving and exploring the memories of Saudi places through AI and community contributions.",
  applicationName: "Saudi Memory AI",
  manifest: "/manifest.webmanifest",
  icons: {
    icon: "/brand-logo.png",
    apple: "/brand-logo.png",
  },
  keywords: [
    "Saudi memory",
    "Saudi heritage",
    "Saudi Memory AI",
    "artificial intelligence",
    "cultural tourism",
  ],
  openGraph: {
    title: "Saudi Memory AI | Every Place Holds a Memory",
    description: "Capture a place, discover its story, and add your memory.",
    locale: "en_US",
    type: "website",
  },
};

export const viewport: Viewport = {
  themeColor: "#073b2d",
  colorScheme: "light",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" dir="ltr">
      <body>{children}</body>
    </html>
  );
}
