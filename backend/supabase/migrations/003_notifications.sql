begin;
-- Devices and delivery history are private even between the two members.
create table public.wedding_push_devices (
  token text primary key check (length(token) between 20 and 4096),
  user_id uuid not null references auth.users(id) on delete cascade,
  enabled_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.wedding_notification_preferences (
  user_id uuid primary key references auth.users(id) on delete cascade,
  enabled boolean not null default false,
  thought boolean not null default true,
  memory boolean not null default true,
  dua boolean not null default true,
  letter boolean not null default true
);
alter table public.couple_members add column notification_gender text not null default 'neutral'
  check (notification_gender in ('masculine','feminine','neutral'));
update public.couple_members set notification_gender='masculine' where user_id='b52d499a-f6a9-4772-ad91-149d853e36e5' and couple_id='couple';
update public.couple_members set notification_gender='feminine' where user_id='86828ab6-34fb-4956-b54c-607d945cb445' and couple_id='couple';
create table public.wedding_notification_queue (
  id uuid primary key default gen_random_uuid(),
  entry_uuid uuid not null references public.wedding_entries(id) on delete cascade,
  recipient_id uuid not null references auth.users(id) on delete cascade,
  event text not null check(event in ('thought','memory','dua','letter','letter_ready')),
  available_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  status text not null default 'pending' check(status in ('pending','processing','sent','skipped','failed')),
  attempts integer not null default 0,
  lease uuid,
  locked_at timestamptz,
  completed_at timestamptz,
  last_error text,
  unique(entry_uuid,event)
);
create index wedding_notification_due on public.wedding_notification_queue(available_at) where status in ('pending','processing');
create table public.wedding_notification_deliveries (
  notification_id uuid not null references public.wedding_notification_queue(id) on delete cascade,
  token text not null,
  primary key(notification_id,token)
);
alter table public.wedding_push_devices enable row level security;
alter table public.wedding_notification_preferences enable row level security;
alter table public.wedding_notification_queue enable row level security;
alter table public.wedding_notification_deliveries enable row level security;
revoke all on public.wedding_push_devices, public.wedding_notification_preferences,
 public.wedding_notification_queue, public.wedding_notification_deliveries from public,anon,authenticated;
grant all on public.wedding_push_devices, public.wedding_notification_preferences,
 public.wedding_notification_queue, public.wedding_notification_deliveries to service_role;

-- Transactional outbox: a notification cannot exist for a failed save.
-- Updates do not repeat creation notifications. Scheduled letters follow edits.
create function public.wedding_enqueue_notification() returns trigger
language plpgsql security definer set search_path='' as $$
declare recipient uuid; opening timestamptz;
begin
  if new.kind not in ('thought','memory','dua','letter') then return new; end if;
  if (select count(*) from public.couple_members where couple_id='couple') <> 2
    or not exists(select 1 from public.couple_members where couple_id='couple' and user_id=new.author_id) then return new; end if;
  if tg_op='UPDATE' then
    if new.kind <> 'letter' or (new.fields->>'openAt' is not distinct from old.fields->>'openAt'
      and new.fields->>'recipientId' is not distinct from old.fields->>'recipientId') then return new; end if;
    -- A changed letter invalidates any in-flight lease as well as pending work.
    delete from public.wedding_notification_queue where entry_uuid=new.id
      and (event='letter_ready' or (event='letter' and status in ('pending','processing')));
  end if;
  if new.kind in ('dua','letter') then
    select user_id into recipient from public.couple_members where couple_id='couple'
      and user_id::text=new.fields->>'recipientId' and user_id<>new.author_id;
  else
    select user_id into recipient from public.couple_members where couple_id='couple' and user_id<>new.author_id;
  end if;
  if recipient is null then return new; end if;
  if new.kind='thought' then
    perform pg_advisory_xact_lock(hashtextextended('push-thought:'||new.author_id::text,0));
    if exists(select 1 from public.wedding_notification_queue q join public.wedding_entries e on e.id=q.entry_uuid
      where q.event='thought' and e.author_id=new.author_id and q.created_at>now()-interval '60 seconds') then return new; end if;
  end if;
  if tg_op='INSERT' then
    insert into public.wedding_notification_queue(entry_uuid,recipient_id,event) values(new.id,recipient,new.kind)
    on conflict do nothing;
  end if;
  if new.kind='letter' then
    begin opening := (new.fields->>'openAt')::timestamptz;
    exception when others then return new; end;
    if opening>now() or tg_op='UPDATE' then
      insert into public.wedding_notification_queue(entry_uuid,recipient_id,event,available_at)
      values(new.id,recipient,'letter_ready',greatest(opening,now())) on conflict do nothing;
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.wedding_enqueue_notification() from public,anon,authenticated;
create trigger wedding_notification_outbox after insert or update on public.wedding_entries
for each row execute function public.wedding_enqueue_notification();

create function public.wedding_claim_notifications() returns setof public.wedding_notification_queue
language sql security definer set search_path='' as $$
  with due as (
    select id from public.wedding_notification_queue
    where available_at<=now() and attempts<8 and (
      status='pending' or (status='processing' and locked_at<now()-interval '5 minutes'))
    order by available_at for update skip locked limit 5
  )
  update public.wedding_notification_queue q set status='processing',attempts=q.attempts+1,
    locked_at=now(),lease=gen_random_uuid()
  from due where q.id=due.id returning q.*;
$$;
revoke all on function public.wedding_claim_notifications() from public,anon,authenticated;
grant execute on function public.wedding_claim_notifications() to service_role;
-- Do not backfill: installation must never flood a partner with historical messages.
commit;
