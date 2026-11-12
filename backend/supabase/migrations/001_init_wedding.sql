-- Supabase schema for Jusqu'à Nous
-- Mirrors Parse Cloud Code constraints for two users in one private couple space.

create extension if not exists pgcrypto;

create table if not exists public.couple_members (
  couple_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now(),
  primary key (couple_id, user_id)
);

comment on table public.couple_members is 'Private mapping of the two users in the couple.';

create table if not exists public.wedding_entries (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  entry_id text not null,
  kind text not null,
  author_id uuid not null references auth.users(id) on delete cascade,
  fields jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint wedding_key_format check (key ~ '^[a-zA-Z0-9_-]{1,100}:[a-zA-Z0-9_-]{1,100}$'),
  constraint wedding_entry_id_format check (entry_id ~ '^[a-zA-Z0-9_-]{1,100}$')
);

comment on table public.wedding_entries is 'Shared/private records (memories, letters, dreams, promises, etc).';

create index if not exists wedding_entries_kind_idx on public.wedding_entries(kind);
create index if not exists wedding_entries_author_idx on public.wedding_entries(author_id);
create index if not exists wedding_entries_created_idx on public.wedding_entries(created_at);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_wedding_entries_updated_at on public.wedding_entries;
create trigger trg_wedding_entries_updated_at
before update on public.wedding_entries
for each row execute function public.touch_updated_at();

alter table public.couple_members enable row level security;
alter table public.wedding_entries enable row level security;

-- Membership visibility: each member can only read rows related to themselves.
drop policy if exists cm_select_self on public.couple_members;
create policy cm_select_self
on public.couple_members
for select
to authenticated
using (user_id = auth.uid());

-- Couple membership is managed by SQL editor / service role only.
drop policy if exists cm_no_client_insert on public.couple_members;
create policy cm_no_client_insert
on public.couple_members
for insert
to authenticated
with check (false);

drop policy if exists cm_no_client_update on public.couple_members;
create policy cm_no_client_update
on public.couple_members
for update
to authenticated
using (false)
with check (false);

drop policy if exists cm_no_client_delete on public.couple_members;
create policy cm_no_client_delete
on public.couple_members
for delete
to authenticated
using (false);

-- Entries: no direct client read/write. Access only through Edge Functions using service role.
drop policy if exists wedding_entries_no_client_select on public.wedding_entries;
create policy wedding_entries_no_client_select
on public.wedding_entries
for select
to authenticated
using (false);

drop policy if exists wedding_entries_no_client_insert on public.wedding_entries;
create policy wedding_entries_no_client_insert
on public.wedding_entries
for insert
to authenticated
with check (false);

drop policy if exists wedding_entries_no_client_update on public.wedding_entries;
create policy wedding_entries_no_client_update
on public.wedding_entries
for update
to authenticated
using (false)
with check (false);

drop policy if exists wedding_entries_no_client_delete on public.wedding_entries;
create policy wedding_entries_no_client_delete
on public.wedding_entries
for delete
to authenticated
using (false);

-- Optional helper view for admin debugging in SQL editor.
create or replace view public.wedding_entry_debug with (security_invoker = true) as
select
  e.id,
  e.key,
  e.entry_id,
  e.kind,
  e.author_id,
  e.fields,
  e.created_at,
  e.updated_at
from public.wedding_entries e;

grant usage on schema public to anon, authenticated;
grant select on public.couple_members to authenticated;
revoke all on public.wedding_entry_debug from public, anon, authenticated;
