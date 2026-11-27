begin;
create table public.couple_vouchers (
 id uuid primary key,
 couple_id text not null,
 sender_id uuid not null,
 recipient_id uuid not null,
 template_key text check(template_key in ('massage','breakfast','evening')),
 title text not null check(length(btrim(title)) between 1 and 80),
 description text not null check(length(btrim(description)) between 1 and 400),
 personal_message text not null default '' check(length(personal_message)<=800),
 icon_key text not null check(icon_key in ('heart','coffee','moon','flower','gift')),
 theme_key text not null check(theme_key in ('cream','sage','forest')),
 status text not null default 'offered' check(status in ('offered','opened','requested','scheduled','completed','cancelled')),
 created_at timestamptz not null default now(), opened_at timestamptz, requested_at timestamptz,
 proposed_for timestamptz, scheduled_for timestamptz, completed_at timestamptz,
 awaiting_id uuid, completion_previous_status text,
 version integer not null default 0,
 check(sender_id<>recipient_id),
 foreign key(couple_id,sender_id) references public.couple_members(couple_id,user_id),
 foreign key(couple_id,recipient_id) references public.couple_members(couple_id,user_id)
);
create table public.couple_voucher_events (
 id uuid primary key,
 voucher_id uuid not null references public.couple_vouchers(id) on delete cascade,
 actor_id uuid not null references auth.users(id),
 action text not null,
 note text not null default '' check(length(note)<=800),
 proposed_for timestamptz,
 from_status text, to_status text not null,
 created_at timestamptz not null default now()
);
create index couple_vouchers_recipient on public.couple_vouchers(recipient_id,created_at desc);
create index couple_vouchers_sender on public.couple_vouchers(sender_id,created_at desc);
create index couple_voucher_event_order on public.couple_voucher_events(voucher_id,created_at);

create function public.voucher_access(c text,s uuid,r uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() in (s,r) and
 exists(select 1 from public.couple_members where couple_id=c and user_id=s) and
 exists(select 1 from public.couple_members where couple_id=c and user_id=r);
$$;
revoke all on function public.voucher_access(text,uuid,uuid) from public,anon;
grant execute on function public.voucher_access(text,uuid,uuid) to authenticated;
alter table public.couple_vouchers enable row level security;
alter table public.couple_voucher_events enable row level security;
revoke all on public.couple_vouchers,public.couple_voucher_events from public,anon,authenticated;
grant select on public.couple_vouchers,public.couple_voucher_events to authenticated;
grant all on public.couple_vouchers,public.couple_voucher_events to service_role;
create policy voucher_read on public.couple_vouchers for select to authenticated
 using(public.voucher_access(couple_id,sender_id,recipient_id));
create policy voucher_event_read on public.couple_voucher_events for select to authenticated
 using(exists(select 1 from public.couple_vouchers v where v.id=voucher_id));

create function public.offer_voucher(p_id uuid,p_recipient uuid,p_title text,p_description text,
 p_message text,p_icon text,p_theme text,p_template text default null)
 returns public.couple_vouchers language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); c text; v public.couple_vouchers;
begin
 if actor is null or actor=p_recipient then raise exception 'Non autorisé'; end if;
 select a.couple_id into c from public.couple_members a join public.couple_members b using(couple_id)
 where a.user_id=actor and b.user_id=p_recipient
 and (select count(*) from public.couple_members m where m.couple_id=a.couple_id)=2;
 if c is null then raise exception 'Destinataire non autorisé'; end if;
 -- The client retains this UUID across retries, including lost network responses.
 perform pg_advisory_xact_lock(hashtextextended(p_id::text,0));
 select * into v from public.couple_vouchers where id=p_id;
 if found then
   if v.sender_id<>actor or v.recipient_id<>p_recipient or v.title<>btrim(p_title)
    or v.description<>btrim(p_description) or v.personal_message<>coalesce(btrim(p_message),'')
    or v.icon_key<>p_icon or v.theme_key<>p_theme or v.template_key is distinct from p_template
   then raise exception 'Identifiant déjà utilisé'; end if;
   return v;
 end if;
 insert into public.couple_vouchers(id,couple_id,sender_id,recipient_id,title,description,personal_message,icon_key,theme_key,template_key)
 values(p_id,c,actor,p_recipient,btrim(p_title),btrim(p_description),coalesce(btrim(p_message),''),p_icon,p_theme,p_template) returning * into v;
 insert into public.couple_voucher_events(id,voucher_id,actor_id,action,to_status) values(gen_random_uuid(),v.id,actor,'offer','offered');
 return v;
end; $$;

create function public.act_on_voucher(p_id uuid,p_operation uuid,p_version integer,p_action text,
 p_note text default '',p_date timestamptz default null)
 returns public.couple_vouchers language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); v public.couple_vouchers; old_status text; event public.couple_voucher_events;
begin
 select * into v from public.couple_vouchers where id=p_id for update;
 if not found or actor is null or not coalesce(public.voucher_access(v.couple_id,v.sender_id,v.recipient_id),false) then raise exception 'Non autorisé'; end if;
 select * into event from public.couple_voucher_events where id=p_operation;
 if found then
   if event.voucher_id<>p_id or event.actor_id<>actor or event.action<>p_action
     or event.note<>coalesce(btrim(p_note),'') or event.proposed_for is distinct from p_date
     then raise exception 'Opération déjà utilisée'; end if;
   return v;
 end if;
 if p_action='open' and actor=v.recipient_id and v.opened_at is not null then return v; end if;
 if p_version is null or v.version<>p_version then raise exception 'Ce bon a changé. Actualise le carnet.'; end if;
 if p_note is null or length(p_note)>800 then raise exception 'Message invalide'; end if;
 if p_date is not null and (not isfinite(p_date) or p_date<now()-interval '1 minute' or p_date>now()+interval '20 years') then raise exception 'Date invalide'; end if;
 old_status:=v.status;
 case p_action
 when 'open' then
   if actor<>v.recipient_id or v.status<>'offered' then raise exception 'Ouverture impossible'; end if;
   v.status:='opened'; v.opened_at:=now();
 when 'request' then
   if actor<>v.recipient_id or v.status<>'opened' then raise exception 'Demande impossible'; end if;
   v.status:='requested'; v.requested_at:=now(); v.proposed_for:=p_date; v.awaiting_id:=v.sender_id;
 when 'withdraw' then
   if actor<>v.recipient_id or v.status<>'requested' then raise exception 'Retrait impossible'; end if;
   v.status:='opened'; v.proposed_for:=null; v.scheduled_for:=null; v.awaiting_id:=null;
 when 'accept' then
   if v.status<>'requested' or actor is distinct from v.awaiting_id then raise exception 'Acceptation impossible'; end if;
   v.status:='scheduled'; v.scheduled_for:=v.proposed_for; v.awaiting_id:=null;
 when 'propose' then
   if actor<>v.sender_id or v.status<>'requested' or p_date is null then raise exception 'Proposition impossible'; end if;
   v.proposed_for:=p_date; v.awaiting_id:=v.recipient_id;
 when 'later' then
   if actor<>v.sender_id or v.status<>'requested' then raise exception 'Report impossible'; end if;
   v.status:='opened'; v.proposed_for:=null; v.scheduled_for:=null; v.awaiting_id:=null;
 when 'complete' then
   if v.status not in ('requested','scheduled') then raise exception 'Réalisation impossible'; end if;
   v.completion_previous_status:=v.status; v.status:='completed'; v.completed_at:=now();
 when 'undo' then
   if v.status<>'completed' then raise exception 'Annulation impossible'; end if;
   v.status:=v.completion_previous_status; v.completed_at:=null; v.completion_previous_status:=null;
 when 'cancel' then
   if actor<>v.sender_id or v.status not in ('offered','opened') then raise exception 'Annulation impossible'; end if;
   v.status:='cancelled';
 else raise exception 'Action inconnue'; end case;
 update public.couple_vouchers set status=v.status,opened_at=v.opened_at,requested_at=v.requested_at,
 proposed_for=v.proposed_for,scheduled_for=v.scheduled_for,completed_at=v.completed_at,
 awaiting_id=v.awaiting_id,completion_previous_status=v.completion_previous_status,version=version+1
 where id=p_id returning * into v;
 insert into public.couple_voucher_events(id,voucher_id,actor_id,action,note,proposed_for,from_status,to_status)
 values(p_operation,p_id,actor,p_action,btrim(p_note),p_date,old_status,v.status);
 return v;
end; $$;
revoke all on function public.offer_voucher(uuid,uuid,text,text,text,text,text,text),
 public.act_on_voucher(uuid,uuid,integer,text,text,timestamptz) from public,anon;
grant execute on function public.offer_voucher(uuid,uuid,text,text,text,text,text,text),
 public.act_on_voucher(uuid,uuid,integer,text,text,timestamptz) to authenticated;

-- Reuse the existing transactional outbox, worker, device preferences and cron.
alter table public.wedding_notification_preferences add column voucher boolean not null default true;
alter table public.wedding_notification_queue alter column entry_uuid drop not null;
alter table public.wedding_notification_queue add column voucher_event_id uuid unique references public.couple_voucher_events(id) on delete cascade;
alter table public.wedding_notification_queue drop constraint wedding_notification_queue_event_check;
alter table public.wedding_notification_queue add constraint wedding_notification_queue_event_check
 check(event in ('thought','memory','dua','letter','letter_ready','voucher'));
alter table public.wedding_notification_queue add constraint notification_source_check
 check((event='voucher' and voucher_event_id is not null and entry_uuid is null) or
       (event<>'voucher' and entry_uuid is not null and voucher_event_id is null));
create function public.enqueue_voucher_notification() returns trigger
language plpgsql security definer set search_path='' as $$
declare v public.couple_vouchers;
begin
 if new.action='open' then return new; end if;
 select * into v from public.couple_vouchers where id=new.voucher_id;
 insert into public.wedding_notification_queue(recipient_id,event,voucher_event_id)
 values(case when new.actor_id=v.sender_id then v.recipient_id else v.sender_id end,'voucher',new.id);
 return new;
end; $$;
revoke all on function public.enqueue_voucher_notification() from public,anon,authenticated;
create trigger voucher_notification after insert on public.couple_voucher_events
 for each row execute function public.enqueue_voucher_notification();
commit;
