begin;
-- Reactions never modify the album JSON, even when both partners react together.
create table if not exists public.memory_reactions (
  entry_key text not null references public.wedding_entries(key) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  emoji text not null check (char_length(emoji) between 1 and 32 and octet_length(emoji)<=128),
  updated_at timestamptz not null default now(),
  primary key(entry_key,user_id),
  constraint memory_reactions_memory_only check(entry_key like 'memory:%')
);
alter table public.memory_reactions enable row level security;
revoke all on public.memory_reactions from public,anon,authenticated;
grant select on public.memory_reactions to authenticated;
drop policy if exists memory_reactions_read on public.memory_reactions;
create policy memory_reactions_read on public.memory_reactions for select to authenticated
using(public.is_wedding_member());

create or replace function public.set_memory_reaction(p_memory_id text,p_emoji text)
returns void language plpgsql security definer set search_path='' as $$
declare v_actor uuid:=auth.uid(); v_key text:='memory:'||p_memory_id;
begin
  if v_actor is null or not public.is_wedding_member() then raise exception 'Accès refusé'; end if;
  if p_memory_id is null or p_memory_id !~ '^[a-zA-Z0-9_-]{1,100}$' then raise exception 'Souvenir invalide'; end if;
  -- Match the existing save/delete lock, including a concurrent deletion.
  perform pg_advisory_xact_lock(hashtextextended(v_key,0));
  if not exists(select 1 from public.wedding_entries where key=v_key and kind='memory') then raise exception 'Souvenir introuvable'; end if;
  if p_emoji is null then
    delete from public.memory_reactions where entry_key=v_key and user_id=v_actor;
    return;
  end if;
  if char_length(p_emoji) not between 1 and 32 or octet_length(p_emoji)>128
     or p_emoji !~ '[🀀-🫿☀-⟿⌚-⏿⬀-⯿↔-⇿©®‼⁉™ℹ〰〽㊗㊙⃣]'
     or p_emoji ~ '[^🀀-🫿☀-⟿⌚-⏿⬀-⯿↔-⇿©®‼⁉™ℹ〰〽㊗㊙⃣0-9#*‍︎️󠀠-󠁿]' then raise exception 'Emoji invalide'; end if;
  insert into public.memory_reactions(entry_key,user_id,emoji)
  values(v_key,v_actor,p_emoji)
  on conflict(entry_key,user_id) do update set emoji=excluded.emoji,updated_at=now();
end;
$$;
revoke all on function public.set_memory_reaction(text,text) from public,anon;
grant execute on function public.set_memory_reaction(text,text) to authenticated;
commit;
