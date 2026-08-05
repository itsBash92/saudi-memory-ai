-- Saudi Memory AI — hardened initial PostgreSQL schema for Supabase
-- Review in a disposable environment before applying to production.

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

-- Public profile data is deliberately separated from authorization data.
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'New member'
    check (char_length(display_name) between 2 and 60),
  avatar_path text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_avatar_path_check check (
    avatar_path is null
    or (
      split_part(avatar_path, '/', 1) = id::text
      and avatar_path !~ '(^|/)\.\.?(/|$)'
      and char_length(avatar_path) between 38 and 500
    )
  )
);

create table public.profile_roles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  role public.user_role not null default 'member',
  assigned_at timestamptz not null default now(),
  assigned_by uuid references public.profiles(id) on delete set null
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
  established_year integer check (established_year is null or established_year between 1 and 2200),
  status public.content_status not null default 'draft',
  cover_media_id uuid,
  moderation_note text,
  verified_at timestamptz,
  verified_by uuid references public.profiles(id) on delete set null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint places_coordinate_pair_check check (
    (latitude is null and longitude is null)
    or (
      latitude is not null
      and longitude is not null
      and latitude between -90 and 90
      and longitude between -180 and 180
    )
  ),
  constraint places_verified_timestamp_check check (
    status <> 'verified' or (verified_at is not null and verified_by is not null)
  )
);

create table public.memories (
  id uuid primary key default gen_random_uuid(),
  place_id uuid not null references public.places(id) on delete cascade,
  contributor_id uuid not null references public.profiles(id) on delete cascade,
  title text not null check (char_length(title) between 3 and 140),
  story text not null check (char_length(story) between 20 and 12000),
  approximate_year integer check (approximate_year is null or approximate_year between 1 and 2200),
  is_approximate_date boolean not null default true,
  publish_anonymously boolean not null default false,
  status public.content_status not null default 'draft',
  confidence numeric(4, 3) check (confidence is null or confidence between 0 and 1),
  moderation_note text,
  verified_at timestamptz,
  verified_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint memories_verified_timestamp_check check (
    status <> 'verified' or (verified_at is not null and verified_by is not null)
  )
);

create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  memory_id uuid references public.memories(id) on delete cascade,
  place_id uuid references public.places(id) on delete cascade,
  kind public.media_kind not null,
  storage_path text not null unique,
  mime_type text not null,
  byte_size bigint not null check (byte_size between 1 and 52428800),
  width integer check (width is null or width > 0),
  height integer check (height is null or height > 0),
  captured_year integer check (captured_year is null or captured_year between 1 and 2200),
  rights_confirmed boolean not null default false,
  exif_removed boolean not null default false,
  status public.content_status not null default 'pending',
  moderation_note text,
  verified_at timestamptz,
  verified_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint media_single_parent_check check ((memory_id is null) <> (place_id is null)),
  constraint media_mime_kind_check check (
    (kind = 'image' and mime_type in ('image/jpeg', 'image/png', 'image/webp'))
    or (kind = 'video' and mime_type = 'video/mp4')
    or (kind = 'audio' and mime_type in ('audio/mpeg', 'audio/wav', 'audio/x-wav'))
  ),
  constraint media_verified_state_check check (
    status <> 'verified'
    or (verified_at is not null and verified_by is not null and exif_removed and rights_confirmed)
  )
);

alter table public.places
  add constraint places_cover_media_id_fkey
  foreign key (cover_media_id) references public.media_assets(id) on delete set null;

create table public.sources (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 3 and 300),
  publisher text,
  url text check (url is null or url ~ '^https?://'),
  citation_text text,
  published_year integer check (published_year is null or published_year between 1 and 2200),
  archived_at timestamptz,
  status public.content_status not null default 'pending',
  moderation_note text,
  verified_at timestamptz,
  verified_by uuid references public.profiles(id) on delete set null,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint sources_reference_check check (
    url is not null or nullif(btrim(citation_text), '') is not null
  ),
  constraint sources_verified_timestamp_check check (
    status <> 'verified' or (verified_at is not null and verified_by is not null)
  )
);

create table public.memory_sources (
  memory_id uuid not null references public.memories(id) on delete cascade,
  source_id uuid not null references public.sources(id) on delete cascade,
  supports_claim text,
  primary key (memory_id, source_id)
);

create table public.ai_reviews (
  id uuid primary key default gen_random_uuid(),
  place_id uuid references public.places(id) on delete cascade,
  memory_id uuid references public.memories(id) on delete cascade,
  media_id uuid references public.media_assets(id) on delete cascade,
  model_provider text not null,
  model_name text not null,
  model_version text,
  decision public.review_decision not null,
  confidence numeric(4, 3) check (confidence is null or confidence between 0 and 1),
  reason_codes text[] not null default '{}',
  safe_summary jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  constraint ai_review_single_target_check check (
    num_nonnulls(place_id, memory_id, media_id) = 1
  )
);

create table public.moderation_reviews (
  id uuid primary key default gen_random_uuid(),
  reviewer_id uuid not null references public.profiles(id) on delete restrict,
  place_id uuid references public.places(id) on delete cascade,
  memory_id uuid references public.memories(id) on delete cascade,
  media_id uuid references public.media_assets(id) on delete cascade,
  source_id uuid references public.sources(id) on delete cascade,
  previous_status public.content_status not null,
  decision public.content_status not null check (decision <> 'draft'),
  note text check (note is null or char_length(note) <= 2000),
  reviewed_at timestamptz not null default now(),
  constraint moderation_review_single_target_check check (
    num_nonnulls(place_id, memory_id, media_id, source_id) = 1
  )
);

create table public.points_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  memory_id uuid references public.memories(id) on delete set null,
  delta integer not null check (delta <> 0),
  reason text not null check (char_length(reason) between 3 and 240),
  idempotency_key text not null unique check (char_length(idempotency_key) between 8 and 160),
  created_at timestamptz not null default now()
);

create table public.badges (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique check (slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'),
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
  fulfilled_at timestamptz,
  constraint redemptions_fulfilled_state_check check (
    (status = 'fulfilled' and fulfilled_at is not null)
    or (status <> 'fulfilled' and fulfilled_at is null)
  )
);

create index places_status_region_idx on public.places(status, region_ar);
create index memories_place_status_idx on public.memories(place_id, status, created_at desc);
create index memories_contributor_idx on public.memories(contributor_id, created_at desc);
create index media_memory_idx on public.media_assets(memory_id);
create index media_place_idx on public.media_assets(place_id);
create index sources_status_idx on public.sources(status, created_at desc);
create index ai_reviews_memory_idx on public.ai_reviews(memory_id, created_at desc);
create index ai_reviews_media_idx on public.ai_reviews(media_id, created_at desc);
create index ai_reviews_place_idx on public.ai_reviews(place_id, created_at desc);
create index moderation_reviews_place_idx on public.moderation_reviews(place_id, reviewed_at desc);
create index moderation_reviews_memory_idx on public.moderation_reviews(memory_id, reviewed_at desc);
create index moderation_reviews_media_idx on public.moderation_reviews(media_id, reviewed_at desc);
create index moderation_reviews_source_idx on public.moderation_reviews(source_id, reviewed_at desc);
create index points_ledger_user_idx on public.points_ledger(user_id, created_at desc);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
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
security definer
set search_path = ''
as $$
declare
  requested_name text := trim(new.raw_user_meta_data ->> 'display_name');
  safe_name text;
begin
  safe_name := case
    when char_length(requested_name) between 2 and 60 then requested_name
    else 'New member'
  end;

  insert into public.profiles (id, display_name)
  values (new.id, safe_name);

  insert into public.profile_roles (user_id)
  values (new.id);

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
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profile_roles
    where user_id = (select auth.uid())
      and role in ('reviewer', 'admin')
  );
$$;

alter table public.profiles enable row level security;
alter table public.profile_roles enable row level security;
alter table public.places enable row level security;
alter table public.memories enable row level security;
alter table public.media_assets enable row level security;
alter table public.sources enable row level security;
alter table public.memory_sources enable row level security;
alter table public.ai_reviews enable row level security;
alter table public.moderation_reviews enable row level security;
alter table public.points_ledger enable row level security;
alter table public.badges enable row level security;
alter table public.user_badges enable row level security;
alter table public.redemptions enable row level security;

create policy "safe profiles are public"
on public.profiles for select
using (true);

create policy "users update their own public profile"
on public.profiles for update to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

create policy "users read their role"
on public.profile_roles for select to authenticated
using (user_id = (select auth.uid()) or public.is_reviewer());

create policy "verified places are public"
on public.places for select
using (status = 'verified' or created_by = (select auth.uid()) or public.is_reviewer());

create policy "members create draft places"
on public.places for insert to authenticated
with check (created_by = (select auth.uid()) and status in ('draft', 'pending'));

create policy "members update their unverified places"
on public.places for update to authenticated
using (created_by = (select auth.uid()) and status <> 'verified')
with check (created_by = (select auth.uid()) and status in ('draft', 'pending'));

create policy "verified memories are public and owners see drafts"
on public.memories for select
using (status = 'verified' or contributor_id = (select auth.uid()) or public.is_reviewer());

create policy "members create their own memories"
on public.memories for insert to authenticated
with check (
  contributor_id = (select auth.uid())
  and status in ('draft', 'pending')
  and exists (
    select 1 from public.places
    where places.id = memories.place_id
      and (
        places.status = 'verified'
        or places.created_by = (select auth.uid())
        or public.is_reviewer()
      )
  )
);

create policy "members update their unverified memories"
on public.memories for update to authenticated
using (contributor_id = (select auth.uid()) and status <> 'verified')
with check (
  contributor_id = (select auth.uid())
  and status in ('draft', 'pending')
  and exists (
    select 1 from public.places
    where places.id = memories.place_id
      and (
        places.status = 'verified'
        or places.created_by = (select auth.uid())
        or public.is_reviewer()
      )
  )
);

create policy "members delete their unverified memories"
on public.memories for delete to authenticated
using (contributor_id = (select auth.uid()) and status <> 'verified');

create policy "owners and reviewers read media metadata"
on public.media_assets for select to authenticated
using (owner_id = (select auth.uid()) or public.is_reviewer());

create policy "verified sources are public"
on public.sources for select
using (status = 'verified' or created_by = (select auth.uid()) or public.is_reviewer());

create policy "members create pending sources"
on public.sources for insert to authenticated
with check (created_by = (select auth.uid()) and status = 'pending');

create policy "members update their pending sources"
on public.sources for update to authenticated
using (created_by = (select auth.uid()) and status in ('draft', 'pending'))
with check (created_by = (select auth.uid()) and status in ('draft', 'pending'));

create policy "accessible memory source links are readable"
on public.memory_sources for select
using (
  exists (
    select 1 from public.memories
    where memories.id = memory_sources.memory_id
      and (
        memories.status = 'verified'
        or memories.contributor_id = (select auth.uid())
        or public.is_reviewer()
      )
  )
  and exists (
    select 1 from public.sources
    where sources.id = memory_sources.source_id
      and (
        sources.status = 'verified'
        or sources.created_by = (select auth.uid())
        or public.is_reviewer()
      )
  )
);

create policy "owners link sources to their memories"
on public.memory_sources for insert to authenticated
with check (
  exists (
    select 1 from public.memories
    where memories.id = memory_sources.memory_id
      and memories.contributor_id = (select auth.uid())
      and memories.status in ('draft', 'pending')
  )
  and exists (
    select 1 from public.sources
    where sources.id = memory_sources.source_id
      and (
        sources.status = 'verified'
        or (
          sources.created_by = (select auth.uid())
          and sources.status in ('draft', 'pending')
        )
      )
  )
);

create policy "owners unlink sources from their memories"
on public.memory_sources for delete to authenticated
using (
  exists (
    select 1 from public.memories
    where memories.id = memory_sources.memory_id
      and memories.contributor_id = (select auth.uid())
      and memories.status in ('draft', 'pending')
  )
);

create policy "reviews visible to contributor and reviewers"
on public.ai_reviews for select to authenticated
using (
  public.is_reviewer()
  or exists (
    select 1 from public.places
    where places.id = ai_reviews.place_id
      and places.created_by = (select auth.uid())
  )
  or exists (
    select 1 from public.memories
    where memories.id = ai_reviews.memory_id
      and memories.contributor_id = (select auth.uid())
  )
  or exists (
    select 1 from public.media_assets
    where media_assets.id = ai_reviews.media_id
      and media_assets.owner_id = (select auth.uid())
  )
);

create policy "moderation history visible to owners and reviewers"
on public.moderation_reviews for select to authenticated
using (
  public.is_reviewer()
  or exists (
    select 1 from public.places
    where places.id = moderation_reviews.place_id
      and places.created_by = (select auth.uid())
  )
  or exists (
    select 1 from public.memories
    where memories.id = moderation_reviews.memory_id
      and memories.contributor_id = (select auth.uid())
  )
  or exists (
    select 1 from public.media_assets
    where media_assets.id = moderation_reviews.media_id
      and media_assets.owner_id = (select auth.uid())
  )
  or exists (
    select 1 from public.sources
    where sources.id = moderation_reviews.source_id
      and sources.created_by = (select auth.uid())
  )
);

create policy "users read their points"
on public.points_ledger for select to authenticated
using (user_id = (select auth.uid()) or public.is_reviewer());

create policy "active badges are public"
on public.badges for select
using (is_active or public.is_reviewer());

create policy "users read their awarded badges"
on public.user_badges for select to authenticated
using (user_id = (select auth.uid()) or public.is_reviewer());

create policy "users read their redemptions"
on public.redemptions for select to authenticated
using (user_id = (select auth.uid()) or public.is_reviewer());

-- Browser clients never insert media metadata directly. This RPC validates ownership,
-- file type, size, path isolation, and the rights attestation before registration.
create or replace function public.register_media(
  p_kind public.media_kind,
  p_storage_path text,
  p_mime_type text,
  p_byte_size bigint,
  p_rights_confirmed boolean,
  p_memory_id uuid default null,
  p_place_id uuid default null,
  p_width integer default null,
  p_height integer default null,
  p_captured_year integer default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_media_id uuid;
  current_user_id uuid := (select auth.uid());
begin
  if current_user_id is null then
    raise exception 'Authentication is required.';
  end if;

  if (p_memory_id is null) = (p_place_id is null) then
    raise exception 'Exactly one parent must be supplied.';
  end if;

  if split_part(p_storage_path, '/', 1) <> current_user_id::text
    or p_storage_path ~ '(^|/)\.\.?(/|$)' then
    raise exception 'The storage path must be inside the authenticated user folder.';
  end if;

  if not p_rights_confirmed then
    raise exception 'Media rights must be confirmed before registration.';
  end if;

  if p_byte_size < 1 or p_byte_size > 52428800 then
    raise exception 'Media must be between 1 byte and 50 MB.';
  end if;

  if not (
    (p_kind = 'image' and p_mime_type in ('image/jpeg', 'image/png', 'image/webp'))
    or (p_kind = 'video' and p_mime_type = 'video/mp4')
    or (p_kind = 'audio' and p_mime_type in ('audio/mpeg', 'audio/wav', 'audio/x-wav'))
  ) then
    raise exception 'The MIME type does not match the media kind.';
  end if;

  if p_memory_id is not null and not exists (
    select 1 from public.memories
    where id = p_memory_id
      and contributor_id = current_user_id
      and status in ('draft', 'pending')
  ) then
    raise exception 'The memory is not editable by the authenticated user.';
  end if;

  if p_place_id is not null and not exists (
    select 1 from public.places
    where id = p_place_id
      and created_by = current_user_id
      and status in ('draft', 'pending')
  ) then
    raise exception 'The place is not editable by the authenticated user.';
  end if;

  insert into public.media_assets (
    owner_id,
    memory_id,
    place_id,
    kind,
    storage_path,
    mime_type,
    byte_size,
    width,
    height,
    captured_year,
    rights_confirmed
  ) values (
    current_user_id,
    p_memory_id,
    p_place_id,
    p_kind,
    p_storage_path,
    p_mime_type,
    p_byte_size,
    p_width,
    p_height,
    p_captured_year,
    true
  ) returning id into new_media_id;

  return new_media_id;
end;
$$;

create or replace function public.review_memory(
  p_memory_id uuid,
  p_status public.content_status,
  p_confidence numeric default null,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_status public.content_status;
begin
  if not public.is_reviewer() then
    raise exception 'Reviewer access is required.';
  end if;

  if p_status is null or p_status = 'draft' then
    raise exception 'Reviewers cannot return content to draft.';
  end if;

  if p_note is not null and char_length(p_note) > 2000 then
    raise exception 'The moderation note is too long.';
  end if;

  if p_status = 'verified' and p_confidence is null then
    raise exception 'Verified memories require a confidence score.';
  end if;

  select status into previous_status
  from public.memories
  where id = p_memory_id
  for update;

  if not found then
    raise exception 'Memory not found.';
  end if;

  update public.memories
  set status = p_status,
      confidence = p_confidence,
      moderation_note = p_note,
      verified_at = case when p_status = 'verified' then now() else null end,
      verified_by = case when p_status = 'verified' then (select auth.uid()) else null end
  where id = p_memory_id;

  insert into public.moderation_reviews (
    reviewer_id, memory_id, previous_status, decision, note
  ) values (
    (select auth.uid()), p_memory_id, previous_status, p_status, p_note
  );
end;
$$;

create or replace function public.review_place(
  p_place_id uuid,
  p_status public.content_status,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_status public.content_status;
begin
  if not public.is_reviewer() then
    raise exception 'Reviewer access is required.';
  end if;

  if p_status is null or p_status = 'draft' then
    raise exception 'Reviewers cannot return content to draft.';
  end if;

  if p_note is not null and char_length(p_note) > 2000 then
    raise exception 'The moderation note is too long.';
  end if;

  select status into previous_status
  from public.places
  where id = p_place_id
  for update;

  if not found then
    raise exception 'Place not found.';
  end if;

  update public.places
  set status = p_status,
      moderation_note = p_note,
      verified_at = case when p_status = 'verified' then now() else null end,
      verified_by = case when p_status = 'verified' then (select auth.uid()) else null end
  where id = p_place_id;

  insert into public.moderation_reviews (
    reviewer_id, place_id, previous_status, decision, note
  ) values (
    (select auth.uid()), p_place_id, previous_status, p_status, p_note
  );
end;
$$;

create or replace function public.review_source(
  p_source_id uuid,
  p_status public.content_status,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_status public.content_status;
begin
  if not public.is_reviewer() then
    raise exception 'Reviewer access is required.';
  end if;

  if p_status is null or p_status = 'draft' then
    raise exception 'Reviewers cannot return content to draft.';
  end if;

  if p_note is not null and char_length(p_note) > 2000 then
    raise exception 'The moderation note is too long.';
  end if;

  select status into previous_status
  from public.sources
  where id = p_source_id
  for update;

  if not found then
    raise exception 'Source not found.';
  end if;

  update public.sources
  set status = p_status,
      moderation_note = p_note,
      verified_at = case when p_status = 'verified' then now() else null end,
      verified_by = case when p_status = 'verified' then (select auth.uid()) else null end
  where id = p_source_id;

  insert into public.moderation_reviews (
    reviewer_id, source_id, previous_status, decision, note
  ) values (
    (select auth.uid()), p_source_id, previous_status, p_status, p_note
  );
end;
$$;

create or replace function public.review_media(
  p_media_id uuid,
  p_status public.content_status,
  p_exif_removed boolean,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  previous_status public.content_status;
begin
  if not public.is_reviewer() then
    raise exception 'Reviewer access is required.';
  end if;

  if p_status is null or p_status = 'draft' then
    raise exception 'Reviewers cannot return content to draft.';
  end if;

  if p_exif_removed is null then
    raise exception 'The EXIF processing state is required.';
  end if;

  if p_note is not null and char_length(p_note) > 2000 then
    raise exception 'The moderation note is too long.';
  end if;

  if p_status = 'verified' and not p_exif_removed then
    raise exception 'Verified media must have EXIF removed.';
  end if;

  select status into previous_status
  from public.media_assets
  where id = p_media_id
  for update;

  if not found then
    raise exception 'Media not found.';
  end if;

  update public.media_assets
  set status = p_status,
      exif_removed = p_exif_removed,
      moderation_note = p_note,
      verified_at = case when p_status = 'verified' then now() else null end,
      verified_by = case when p_status = 'verified' then (select auth.uid()) else null end
  where id = p_media_id;

  insert into public.moderation_reviews (
    reviewer_id, media_id, previous_status, decision, note
  ) values (
    (select auth.uid()), p_media_id, previous_status, p_status, p_note
  );
end;
$$;

create or replace function public.award_points(
  p_user_id uuid,
  p_memory_id uuid,
  p_delta integer,
  p_reason text,
  p_idempotency_key text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  ledger_id uuid;
  resulting_balance bigint;
begin
  if not public.is_reviewer() then
    raise exception 'Reviewer access is required.';
  end if;

  if p_user_id is null or p_delta is null or p_delta = 0
    or p_reason is null or char_length(p_reason) not between 3 and 240
    or p_idempotency_key is null
    or char_length(p_idempotency_key) not between 8 and 160 then
    raise exception 'Invalid points event.';
  end if;

  if p_memory_id is not null and not exists (
    select 1 from public.memories
    where id = p_memory_id and contributor_id = p_user_id
  ) then
    raise exception 'The memory does not belong to the points recipient.';
  end if;

  -- Serialize balance changes for one user so concurrent debits cannot overspend.
  perform pg_advisory_xact_lock(hashtextextended(p_user_id::text, 0));

  select id into ledger_id
  from public.points_ledger
  where idempotency_key = p_idempotency_key
    and user_id = p_user_id
    and delta = p_delta;

  if ledger_id is not null then
    return ledger_id;
  end if;

  if exists (
    select 1 from public.points_ledger where idempotency_key = p_idempotency_key
  ) then
    raise exception 'The idempotency key is already used by a different event.';
  end if;

  select coalesce(sum(delta), 0) + p_delta
  into resulting_balance
  from public.points_ledger
  where user_id = p_user_id;

  if resulting_balance < 0 then
    raise exception 'The points balance cannot become negative.';
  end if;

  insert into public.points_ledger (
    user_id,
    memory_id,
    delta,
    reason,
    idempotency_key
  ) values (
    p_user_id,
    p_memory_id,
    p_delta,
    p_reason,
    p_idempotency_key
  ) returning id into ledger_id;

  return ledger_id;
end;
$$;

create or replace function public.award_badge(
  p_user_id uuid,
  p_badge_id uuid,
  p_memory_id uuid default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_reviewer() then
    raise exception 'Reviewer access is required.';
  end if;

  insert into public.user_badges (user_id, badge_id, awarded_for_memory_id)
  values (p_user_id, p_badge_id, p_memory_id)
  on conflict (user_id, badge_id) do nothing;
end;
$$;

create or replace function public.get_my_profile_stats()
returns table (points_balance bigint, contribution_count bigint)
language sql
stable
set search_path = ''
as $$
  select
    coalesce((
      select sum(delta) from public.points_ledger
      where user_id = (select auth.uid())
    ), 0)::bigint,
    (
      select count(*) from public.memories
      where contributor_id = (select auth.uid()) and status = 'verified'
    )::bigint;
$$;

-- Remove broad browser privileges and grant only the operations the client needs.
revoke all on public.profiles from anon, authenticated;
revoke all on public.profile_roles from anon, authenticated;
revoke all on public.places from anon, authenticated;
revoke all on public.memories from anon, authenticated;
revoke all on public.media_assets from anon, authenticated;
revoke all on public.sources from anon, authenticated;
revoke all on public.memory_sources from anon, authenticated;
revoke all on public.ai_reviews from anon, authenticated;
revoke all on public.moderation_reviews from anon, authenticated;
revoke all on public.points_ledger from anon, authenticated;
revoke all on public.badges from anon, authenticated;
revoke all on public.user_badges from anon, authenticated;
revoke all on public.redemptions from anon, authenticated;

grant select (id, display_name, avatar_path, created_at, updated_at)
  on public.profiles to anon, authenticated;
grant select (
  id, slug, name_ar, name_en, city_ar, region_ar, latitude, longitude,
  location_precision_m, short_story_ar, established_year, status,
  cover_media_id, verified_at, created_at, updated_at
) on public.places to anon, authenticated;
grant select (
  id, place_id, title, story, approximate_year, is_approximate_date,
  publish_anonymously, status, confidence, verified_at, created_at, updated_at
) on public.memories to anon, authenticated;
grant select (
  id, title, publisher, url, citation_text, published_year, archived_at,
  status, verified_at, created_at
) on public.sources to anon, authenticated;
grant select on public.memory_sources, public.badges to anon, authenticated;
grant select on public.profile_roles, public.media_assets, public.ai_reviews,
  public.moderation_reviews, public.points_ledger, public.user_badges,
  public.redemptions to authenticated;

grant update (display_name, avatar_path) on public.profiles to authenticated;

grant insert (
  slug, name_ar, name_en, city_ar, region_ar, latitude, longitude,
  location_precision_m, short_story_ar, established_year, status, created_by
) on public.places to authenticated;
grant update (
  slug, name_ar, name_en, city_ar, region_ar, latitude, longitude,
  location_precision_m, short_story_ar, established_year, status
) on public.places to authenticated;

grant insert (
  place_id, contributor_id, title, story, approximate_year,
  is_approximate_date, publish_anonymously, status
) on public.memories to authenticated;
grant update (
  place_id, title, story, approximate_year, is_approximate_date,
  publish_anonymously, status
) on public.memories to authenticated;
grant delete on public.memories to authenticated;

grant insert (
  title, publisher, url, citation_text, published_year, archived_at, status, created_by
) on public.sources to authenticated;
grant update (
  title, publisher, url, citation_text, published_year, archived_at, status
) on public.sources to authenticated;
grant insert, delete on public.memory_sources to authenticated;

revoke execute on function public.set_updated_at() from public, anon, authenticated;
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.is_reviewer() from public, anon, authenticated;
revoke execute on function public.register_media(
  public.media_kind, text, text, bigint, boolean, uuid, uuid, integer, integer, integer
) from public, anon, authenticated;
revoke execute on function public.review_memory(uuid, public.content_status, numeric, text)
  from public, anon, authenticated;
revoke execute on function public.review_place(uuid, public.content_status, text)
  from public, anon, authenticated;
revoke execute on function public.review_source(uuid, public.content_status, text)
  from public, anon, authenticated;
revoke execute on function public.review_media(uuid, public.content_status, boolean, text)
  from public, anon, authenticated;
revoke execute on function public.award_points(uuid, uuid, integer, text, text)
  from public, anon, authenticated;
revoke execute on function public.award_badge(uuid, uuid, uuid)
  from public, anon, authenticated;
revoke execute on function public.get_my_profile_stats()
  from public, anon, authenticated;

grant execute on function public.is_reviewer() to anon, authenticated;
grant execute on function public.register_media(
  public.media_kind, text, text, bigint, boolean, uuid, uuid, integer, integer, integer
) to authenticated;
grant execute on function public.review_memory(uuid, public.content_status, numeric, text)
  to authenticated;
grant execute on function public.review_place(uuid, public.content_status, text)
  to authenticated;
grant execute on function public.review_source(uuid, public.content_status, text)
  to authenticated;
grant execute on function public.review_media(uuid, public.content_status, boolean, text)
  to authenticated;
grant execute on function public.award_points(uuid, uuid, integer, text, text)
  to authenticated;
grant execute on function public.award_badge(uuid, uuid, uuid)
  to authenticated;
grant execute on function public.get_my_profile_stats() to authenticated;

-- Private storage: files are isolated by the first path segment (the user's UUID).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'memory-media',
  'memory-media',
  false,
  52428800,
  array['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'audio/mpeg', 'audio/wav', 'audio/x-wav']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

create policy "users upload to their own media folder"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'memory-media'
  and (storage.foldername(name))[1] = (select auth.uid()::text)
);

create policy "users read their own media objects"
on storage.objects for select to authenticated
using (
  bucket_id = 'memory-media'
  and (
    (storage.foldername(name))[1] = (select auth.uid()::text)
    or public.is_reviewer()
  )
);

-- There is intentionally no browser UPDATE policy for storage objects, review fields,
-- roles, AI reviews, points, badges, or redemptions. Service operations and the audited
-- RPCs above own those mutations.
