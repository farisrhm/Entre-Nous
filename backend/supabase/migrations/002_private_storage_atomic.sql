begin;
-- Close the existing leak, including already-deployed databases.
revoke all on public.wedding_entry_debug from public, anon, authenticated;
alter view public.wedding_entry_debug set (security_invoker = true);

create or replace function public.is_wedding_member()
returns boolean language sql stable security definer set search_path = '' as $$
  select (select count(*) from public.couple_members where couple_id = 'couple') = 2
    and exists (select 1 from public.couple_members where couple_id = 'couple' and user_id = auth.uid());
$$;
revoke all on function public.is_wedding_member() from public, anon;
grant execute on function public.is_wedding_member() to authenticated;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('wedding-photos', 'wedding-photos', false, 20971520, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create policy wedding_photos_read on storage.objects for select to authenticated
using (bucket_id = 'wedding-photos' and public.is_wedding_member());
create policy wedding_photos_insert on storage.objects for insert to authenticated
with check (bucket_id = 'wedding-photos' and public.is_wedding_member()
  and (storage.foldername(name))[1] = auth.uid()::text
  and name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}(\.thumb)?\.(jpeg|png|webp)$');
-- No client UPDATE/DELETE: references are immutable and can be shared by albums.
-- Restrictive policies also prevent pre-existing permissive policies from opening this bucket.
create policy wedding_photos_read_guard on storage.objects as restrictive for select to public
using (bucket_id <> 'wedding-photos' or public.is_wedding_member());
create policy wedding_photos_insert_guard on storage.objects as restrictive for insert to public
with check (bucket_id <> 'wedding-photos' or (public.is_wedding_member()
  and (storage.foldername(name))[1] = auth.uid()::text
  and name ~ '^[0-9a-f-]{36}/[0-9a-f]{32}(\.thumb)?\.(jpeg|png|webp)$'));
create policy wedding_photos_update_guard on storage.objects as restrictive for update to public
using (bucket_id <> 'wedding-photos') with check (bucket_id <> 'wedding-photos');
create policy wedding_photos_delete_guard on storage.objects as restrictive for delete to public
using (bucket_id <> 'wedding-photos');

-- Only verified Edge Functions may call these RPCs with an authenticated actor id.
create or replace function public.wedding_save_atomic(
  p_actor uuid, p_kind text, p_id text, p_fields jsonb, p_schema_version integer
) returns void language plpgsql security definer set search_path = '' as $$
declare
  v_key text := p_kind || ':' || p_id;
  v_existing public.wedding_entries%rowtype;
  v_fields jsonb := p_fields;
  v_photo text;
begin
  if (select count(*) from public.couple_members where couple_id = 'couple') <> 2
     or not exists (select 1 from public.couple_members where couple_id = 'couple' and user_id = p_actor) then
    raise exception 'Accès refusé';
  end if;
  if p_kind not in ('memory','letter','dream','promise','thought','openWhen','happiness','dua','intention')
     or p_id !~ '^[a-zA-Z0-9_-]{1,100}$' or jsonb_typeof(p_fields) <> 'object' then
    raise exception 'Contenu invalide';
  end if;
  if p_kind = 'promise' and p_id <> 'promise-' || p_actor::text then
    raise exception 'Promesse privée';
  end if;
  -- Lock even an absent key, so concurrent inserts cannot steal authorship.
  perform pg_advisory_xact_lock(hashtextextended(v_key, 0));
  select * into v_existing from public.wedding_entries where key = v_key for update;
  if found then
    if p_kind in ('letter','promise','thought','openWhen','happiness','dua') and v_existing.author_id <> p_actor then
      raise exception 'Seul l’auteur peut modifier ce contenu';
    end if;
    if p_kind = 'memory' and coalesce(p_schema_version, 1) < 2
       and jsonb_array_length(coalesce(v_existing.fields->'photos','[]'::jsonb)) > 1 then
      raise exception 'Mets l’application à jour';
    end if;
    if p_kind = 'memory' and coalesce(p_schema_version, 1) < 3
       and exists (select 1 from jsonb_array_elements_text(coalesce(v_existing.fields->'photos','[]'::jsonb)) p where p like 'storage:%') then
      raise exception 'Mets l’application à jour';
    end if;
    if v_fields ? 'createdAt' then
      v_fields := jsonb_set(v_fields,'{createdAt}',coalesce(v_existing.fields->'createdAt',to_jsonb(v_existing.created_at)));
    end if;
  end if;
  if p_kind = 'memory' then
    for v_photo in select jsonb_array_elements_text(coalesce(v_fields->'photos','[]'::jsonb)) loop
      if v_photo like 'storage:%' and not exists (
        select 1 from storage.objects o join public.couple_members m
          on m.user_id::text = split_part(o.name,'/',1) and m.couple_id = 'couple'
        where o.bucket_id = 'wedding-photos' and 'storage:wedding-photos/' || o.name = v_photo
      ) then raise exception 'Photo privée introuvable'; end if;
    end loop;
  end if;
  if v_existing.id is null then
    insert into public.wedding_entries(key, entry_id, kind, author_id, fields)
    values (v_key, p_id, p_kind, p_actor, v_fields);
  else
    update public.wedding_entries set fields = v_fields where id = v_existing.id;
  end if;
end;
$$;

create or replace function public.wedding_delete_atomic(p_actor uuid, p_kind text, p_id text)
returns void language plpgsql security definer set search_path = '' as $$
declare v_existing public.wedding_entries%rowtype; v_key text := p_kind || ':' || p_id;
begin
  if (select count(*) from public.couple_members where couple_id = 'couple') <> 2
     or not exists (select 1 from public.couple_members where couple_id = 'couple' and user_id = p_actor) then
    raise exception 'Accès refusé';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_key, 0));
  select * into v_existing from public.wedding_entries where key = v_key for update;
  if not found then return; end if;
  if v_existing.kind in ('letter','promise','thought','openWhen','happiness','dua') and v_existing.author_id <> p_actor then
    raise exception 'Seul l’auteur peut supprimer ce contenu';
  end if;
  delete from public.wedding_entries where id = v_existing.id;
end;
$$;
revoke all on function public.wedding_save_atomic(uuid,text,text,jsonb,integer) from public, anon, authenticated;
revoke all on function public.wedding_delete_atomic(uuid,text,text) from public, anon, authenticated;
grant execute on function public.wedding_save_atomic(uuid,text,text,jsonb,integer) to service_role;
grant execute on function public.wedding_delete_atomic(uuid,text,text) to service_role;
commit;
