begin;
create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron;
-- Only the scheduler can invoke the worker; its secret is held in Vault.
create or replace function public.wedding_dispatch_tick() returns bigint
language plpgsql security definer set search_path='' as $$
declare secret text; endpoint text; request_id bigint;
begin
  select decrypted_secret into secret from vault.decrypted_secrets where name='wedding_push_dispatch_secret' limit 1;
  select decrypted_secret into endpoint from vault.decrypted_secrets where name='wedding_push_dispatch_url' limit 1;
  if secret is null or endpoint is null then return null; end if;
  -- No empty invocations or Google OAuth requests when the queue is idle.
  if not exists(select 1 from public.wedding_notification_queue where available_at<=now() and attempts<8
    and (status='pending' or (status='processing' and locked_at<now()-interval '5 minutes'))) then return null; end if;
  select net.http_post(url:=endpoint, headers:=jsonb_build_object('Authorization','Bearer '||secret,'Content-Type','application/json'),
    body:='{}'::jsonb,timeout_milliseconds:=120000) into request_id;
  return request_id;
end;
$$;
revoke all on function public.wedding_dispatch_tick() from public,anon,authenticated;
select cron.schedule('wedding-push-dispatch','* * * * *','select public.wedding_dispatch_tick();');
commit;
