import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import test from "node:test";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const read = (path) => readFileSync(resolve(root, path), "utf8");

test("quality checks cannot bypass TypeScript or tests", () => {
  const packageJson = JSON.parse(read("package.json"));
  const nextConfig = read("next.config.ts");
  const gitignore = read(".gitignore");

  assert.equal(packageJson.private, true);
  assert.match(packageJson.scripts.check, /npm run typecheck/);
  assert.match(packageJson.scripts.check, /npm run test/);
  assert.doesNotMatch(nextConfig, /ignoreBuildErrors/);
  assert.match(gitignore, /^next-env\.d\.ts$/m);
});

test("all prototype content is explicitly labelled as illustrative", () => {
  const page = read("app/page.tsx");
  const explorer = read("components/memory-explorer.tsx");
  const scanDemo = read("components/scan-demo.tsx");
  const mockData = read("lib/mock-data.ts");

  assert.match(page, /Illustrative memory/);
  assert.match(explorer, /Illustrative demo data/);
  assert.match(scanDemo, /Illustrative result · no live AI used/);
  assert.doesNotMatch(scanDemo, /available in a future release/i);
  assert.doesNotMatch(mockData, /Umm Khalid|Salem Al-Harbi|Noura Al-Alawi/);
  assert.equal((mockData.match(/isIllustrative: true/g) ?? []).length, 6);
});

test("database migration keeps authorization and points out of public profiles", () => {
  const sql = read("supabase/migrations/202608050001_initial_schema.sql");
  const profileDefinition = sql.match(/create table public\.profiles \(([\s\S]*?)\n\);/)?.[1];

  assert.ok(profileDefinition, "profiles table definition is missing");
  assert.doesNotMatch(profileDefinition, /role|points_balance|contribution_count/);
  assert.match(sql, /create table public\.profile_roles/);
  assert.match(sql, /create or replace function public\.award_points/);
  assert.match(sql, /revoke all on public\.profile_roles from anon, authenticated/);
});

test("database migration enforces parent, coordinate, source, and media safeguards", () => {
  const sql = read("supabase/migrations/202608050001_initial_schema.sql");

  assert.match(sql, /latitude is not null[\s\S]*longitude is not null/);
  assert.match(sql, /media_single_parent_check check \(\(memory_id is null\) <> \(place_id is null\)\)/);
  assert.match(sql, /ai_review_single_target_check check \([\s\S]*num_nonnulls\(place_id, memory_id, media_id\) = 1/);
  assert.match(sql, /create policy "verified sources are public"/);
  assert.match(sql, /users read their awarded badges/);
  assert.doesNotMatch(sql, /awarded badges are public/);
  assert.match(sql, /storage\.foldername\(name\)/);
  assert.match(sql, /public\.register_media/);
  assert.match(sql, /create table public\.moderation_reviews/);
  assert.match(sql, /pg_advisory_xact_lock/);
});

test("database grants do not expose contributor or moderation fields publicly", () => {
  const sql = read("supabase/migrations/202608050001_initial_schema.sql");
  const publicMemoryGrant = sql.match(
    /grant select \(([\s\S]*?)\) on public\.memories to anon, authenticated;/,
  )?.[1];

  assert.ok(publicMemoryGrant, "column-scoped public memories grant is missing");
  assert.doesNotMatch(publicMemoryGrant, /contributor_id|moderation_note|verified_by/);
  assert.doesNotMatch(sql, /grant select on public\.profiles, public\.places, public\.memories/);
  assert.doesNotMatch(
    sql.match(/grant insert \(([\s\S]*?)\) on public\.places to authenticated;/)?.[1] ?? "",
    /cover_media_id/,
  );
});

test("PWA manifest does not falsely claim the original logo is maskable", () => {
  const manifest = JSON.parse(read("public/manifest.webmanifest"));

  assert.equal(manifest.icons[0].purpose, "any");
  assert.equal(manifest.scope, "/");
});

test("local Markdown links resolve with exact casing", () => {
  const markdownFiles = [
    "README.md",
    "CONTRIBUTING.md",
    "SECURITY.md",
    "docs/ARCHITECTURE.md",
    "docs/DATA_MODEL.md",
    "docs/DEMO_SCRIPT.md",
    "docs/PRODUCT.md",
    "docs/ROADMAP.md",
  ];

  for (const file of markdownFiles) {
    const content = read(file);
    const links = [...content.matchAll(/\[[^\]]+\]\(([^)]+)\)/g)].map((match) => match[1]);

    for (const link of links) {
      if (/^(?:https?:|mailto:|#)/.test(link)) continue;
      const target = link.split("#", 1)[0];
      assert.ok(existsSync(resolve(root, dirname(file), target)), `${file} links to missing ${link}`);
    }
  }
});
