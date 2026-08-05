-- Saudi Memory AI — initial PostgreSQL schema for Supabase
-- Apply only after reviewing the policies against the target environment.

create extension if not exists pgcrypto;

create type public.user_role as enum ('member', 'reviewer', 'admin');
create type public.content_status as enum (
  'draft',
  'pending',
  'verified',
  'needs_context',
  'rejected'
);
create type public.media_kind as enum ('image', 'video', 'audio');
create type public.review_decision as enum ('pass', 'flag', 'reject', 'needs_human');
create type public.redemption_status as enum ('requested', 'processing', 'fulfilled', 'cancelled');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (char_length(display_name) between 2 and 60),
  avatar_path text,
  role public.user_role not null default 'member',
  points_balance integer not null default 0 check (points_balance >= 0),
  contribution_count integer not null default 0 check (contribution_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.places (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
  name_ar text not null,
  name_en text,
  city_ar text not null,
  region_ar text not null,
  latitude double precision,
  longitude double precision,
  location_precision_m integer check (location_precision_m is null or location_precision_m > 0),
  short_story_ar text,
  established_year integer,
  status public.content_status not null default 'draft',
  cover_media_id uuid,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (latitude is null and longitude is null)
    or (latitude between -90 and 90 and longitude between -180 and 180)
  )
);

create table public.memories (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade,
  contributor_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 140),
  story text not null check (char_length(story) between 20 and 12000),
  approximate_year integer check (approximate_year between 1700 and 2200),
  is_approximate_date boolean not null default true,
  publish_anonymously boolean not null default false,
  status public.content_status not null default 'draft',
  confidence numeric(4, 3) check (confidence between 0 and 1),
  moderation_note text,
  verified_at timestamptz,
  verified_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  memory_id uuid references public.memories(id) on delete cascade,
  place_id uuid references public.places(id) on delete cascade,
  kind public.media_kind not null,
  storage_path text not null unique,
  mime_type text not null,
  byte_size bigint not null check (byte_size > 0),
  width integer check (width is null or width > 0),
  height integer check (height is null or height > 0),
  captured_year integer check (captured_year between 1700 and 2200),
  rights_confirmed boolean not null default false,
  exif_removed boolean not null default false,
  status public.content_status not null default 'pending',
  created_at timestamptz not null default now(),
  check (memory_id is not null or place_id is not null)
);

alter table public.places
  add constraint places_cover_media_id_fkey
  foreign key (cover_media_id) references public.media_assets(id) on delete set null;

create table public.sources (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  publisher text,
  url text,
  citation_text text,
  published_year integer check (published_year between 1400 and 2200),
  archived_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  check (url is not null or citation_text is not null)
);

create table public.memory_sources (
  memory_id uuid not null references public.memories(id) on delete cascade,
  source_id uuid not null references public.sources(id) on delete cascade,
  supports_claim text,
  primary key (memory_id, source_id)
);

create table public.ai_reviews (
  id uuid primary key default gen_random_uuid(),
  memory_id uuid references public.memories(id) on delete cascade,
  media_id uuid references public.media_assets(id) on delete cascade,
  model_provider text not null,
  model_name text not null,
  model_version text,
  decision public.review_decision not null,
  confidence numeric(4, 3) check (confidence between 0 and 1),
  reason_codes text[] not null default '{}',
  safe_summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  check (memory_id is not null or media_id is not null)
);

create table public.points_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  memory_id uuid references public.memories(id) on delete set null,
  delta integer not null check (delta <> 0),
  reason text not null,
  idempotency_key text not null unique,
  created_at timestamptz not null default now()
);

create table public.badges (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name_ar text not null,
  description_ar text not null,
  icon_path text,
  points_threshold integer check (points_threshold is null or points_threshold >= 0),
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.user_badges (
  user_id uuid not null references public.profiles(id) on delete cascade,
  badge_id uuid not null references public.badges(id) on delete cascade,
  awarded_for_memory_id uuid references public.memories(id) on delete set null,
  awarded_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);

create table public.redemptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  points_cost integer not null check (points_cost > 0),
  partner_code text not null,
  reward_code text not null,
  status public.redemption_status not null default 'requested',
  partner_reference text,
  requested_at timestamptz not null default now(),
  fulfilled_at timestamptz
);

create index places_status_region_idx on public.places(status, region_ar);
create index memories_place_status_idx on public.memories(place_id, status, created_at desc);
create index memories_contributor_idx on public.memories(contributor_id, created_at desc);
create index media_memory_idx on public.media_assets(memory_id);
create index ai_reviews_memory_idx on public.ai_reviews(memory_id, created_at desc);
create index points_ledger_user_idx on public.points_ledger(user_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

create trigger places_set_updated_at
before update on public.places
for each row execute function public.set_updated_at();

create trigger memories_set_updated_at
before update on public.memories
for each row execute function public.set_updated_at();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name', ''), 'New member')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.is_reviewer()
returns boolean
language sql
stable
security definer set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid() and role in ('reviewer', 'admin')
  );
$$;

alter table public.profiles enable row level security;
alter table public.places enable row level security;
alter table public.memories enable row level security;
alter table public.media_assets enable row level security;
alter table public.sources enable row level security;
alter table public.memory_sources enable row level security;
alter table public.ai_reviews enable row level security;
alter table public.points_ledger enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;
alter table public.redemptions enable row level security;

create policy "profiles are readable by authenticated users"
on public.profiles for select to authenticated
using (true);

create policy "users update their own profile"
on public.profiles for update to authenticated
using (id = auth.uid())
with check (id = auth.uid() and role = (select role from public.profiles where id = auth.uid()));

create policy "verified places are public"
on public.places for select
using (status = 'verified' or created_by = auth.uid() or public.is_reviewer());

create policy "members create draft places"
on public.places for insert to authenticated
with check (created_by = auth.uid() and status in ('draft', 'pending'));

create policy "verified memories are public and owners see drafts"
on public.memories for select
using (status = 'verified' or contributor_id = auth.uid() or public.is_reviewer());

create policy "members create their own memories"
on public.memories for insert to authenticated
with check (contributor_id = auth.uid() and status in ('draft', 'pending'));

create policy "members update unverified memories"
on public.memories for update to authenticated
using (contributor_id = auth.uid() and status <> 'verified')
with check (contributor_id = auth.uid() and status in ('draft', 'pending'));

create policy "reviewers update content status"
on public.memories for update to authenticated
using (public.is_reviewer())
with check (public.is_reviewer());

create policy "owners and reviewers read media metadata"
on public.media_assets for select to authenticated
using (owner_id = auth.uid() or public.is_reviewer() or status = 'verified');

create policy "owners register media"
on public.media_assets for insert to authenticated
with check (owner_id = auth.uid() and status = 'pending');

create policy "sources are public"
on public.sources for select
using (true);

create policy "memory source links are public"
on public.memory_sources for select
using (true);

create policy "reviews visible to contributor and reviewers"
on public.ai_reviews for select to authenticated
using (
  public.is_reviewer()
  or exists (
    select 1 from public.memories
    where memories.id = ai_reviews.memory_id
      and memories.contributor_id = auth.uid()
  )
  or exists (
    select 1 from public.media_assets
    where media_assets.id = ai_reviews.media_id
      and media_assets.owner_id = auth.uid()
  )
);

create policy "users read their points"
on public.points_ledger for select to authenticated
using (user_id = auth.uid() or public.is_reviewer());

create policy "active badges are public"
on public.badges for select
using (is_active or public.is_reviewer());

create policy "awarded badges are public"
on public.user_badges for select
using (true);

create policy "users read their redemptions"
on public.redemptions for select to authenticated
using (user_id = auth.uid() or public.is_reviewer());

-- Deliberately no client INSERT policy for points, badges, AI reviews, or redemptions.
-- Those mutations must run through audited server-side functions using idempotency keys.
