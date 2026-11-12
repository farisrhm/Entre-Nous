-- Run separately in Supabase SQL Editor after the migrations.
-- Fill in first_name after confirming which UUID belongs to which person.
-- Does not delete existing memberships, users, or entries.
begin;
do $$
declare
  first_id uuid := 'b52d499a-f6a9-4772-ad91-149d853e36e5';
  second_id uuid := '86828ab6-34fb-4956-b54c-607d945cb445';
  first_name text := ''; -- REQUIRED: 'Alyssa' or 'Faris'
  second_name text;
begin
  if first_name not in ('Alyssa','Faris') then
    raise exception 'Renseigner first_name avant exécution : Alyssa ou Faris.';
  end if;
  second_name := case when first_name = 'Alyssa' then 'Faris' else 'Alyssa' end;
  if (select count(*) from auth.users where id in (first_id,second_id)) <> 2 then
    raise exception 'Les deux utilisateurs Auth doivent exister dans ce projet.';
  end if;
  if exists (select 1 from public.couple_members where couple_id = 'couple' and user_id not in (first_id,second_id)) then
    raise exception 'Un ancien membre existe. Examiner ses contenus avant de remplacer son appartenance au couple.';
  end if;
  insert into public.couple_members(couple_id,user_id,display_name)
  values ('couple',first_id,first_name),('couple',second_id,second_name)
  on conflict (couple_id,user_id) do update set display_name=excluded.display_name;
end;
$$;
commit;
