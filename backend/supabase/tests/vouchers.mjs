// Real PostgreSQL semantics in an ephemeral PGlite database. Never production.
import { readFile } from 'node:fs/promises';
import assert from 'node:assert/strict';
const {PGlite}=await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
const db=new PGlite();
const a='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',b='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
 c='cccccccc-cccc-4ccc-8ccc-cccccccccccc',d='dddddddd-dddd-4ddd-8ddd-dddddddddddd';
await db.exec(`
create role anon; create role authenticated; create role service_role bypassrls;
create schema auth;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
grant usage on schema auth to authenticated,anon;
insert into auth.users values ('${a}'),('${b}'),('${c}'),('${d}');
`);
for(const file of ['001_init_wedding.sql','003_notifications.sql','005_couple_vouchers.sql']) {
 const sql=await readFile(new URL('../migrations/'+file,import.meta.url),'utf8');
 await db.exec(sql.replace('create extension if not exists pgcrypto;',''));
}
await db.exec(`insert into public.couple_members(couple_id,user_id,display_name) values ('couple','${a}','A'),('couple','${b}','B'),('other','${c}','C'),('other','${d}','D');`);
async function asUser(id,sql,args=[]) {
 await db.exec('begin;set local role authenticated;');
 try {await db.query("select set_config('request.jwt.claim.sub',$1,true)",[id]);const r=await db.query(sql,args);await db.exec('commit');return r;}
 catch(e){await db.exec('rollback');throw e;}
}
const offer=(actor,id,recipient=b,template='massage',title='Bon pour un massage')=>asUser(actor,'select * from public.offer_voucher($1,$2,$3,$4,$5,$6,$7,$8)',[id,recipient,title,'30 minutes de détente','Pour toi','heart','cream',template]);
const act=(actor,v,action,date=null,operation=crypto.randomUUID())=>asUser(actor,'select * from public.act_on_voucher($1,$2,$3,$4,$5,$6)',[v.id,operation,v.version,action,'Un petit mot',date]).then(r=>r.rows[0]);
const count=async(actor,table)=> (await asUser(actor,`select * from public.${table}`)).rows.length;
try {
 const id=crypto.randomUUID();
 let v=(await offer(a,id)).rows[0];
 assert.equal(v.sender_id,a);assert.equal(v.recipient_id,b);assert.equal(v.status,'offered');
 await offer(a,id);assert.equal(await count(a,'couple_vouchers'),1);
 assert.equal(await count(b,'couple_vouchers'),1);
 assert.equal(await count(c,'couple_vouchers'),0);assert.equal(await count(c,'couple_voucher_events'),0);
 await assert.rejects(offer(a,crypto.randomUUID(),c));
 await assert.rejects(offer(a,crypto.randomUUID(),a));
 await assert.rejects(offer(c,id,b));
 await assert.rejects(offer(a,crypto.randomUUID(),b,null,''));
 await assert.rejects(asUser(a,"update public.couple_vouchers set sender_id=$1",[b]));
 await assert.rejects(asUser(b,"insert into public.couple_voucher_events(id,voucher_id,actor_id,action,to_status) values(gen_random_uuid(),$1,$2,'complete','completed')",[id,b]));
 await assert.rejects(act(c,v,'open'));
 await assert.rejects(act(a,v,'open'));
 await assert.rejects(act(b,v,'complete'));
 await assert.rejects(act('',v,'open'));
 v=await act(b,v,'open');assert.equal(v.status,'opened');
 const openedVersion=v.version;
 v=await act(b,v,'open');assert.equal(v.version,openedVersion);
 await assert.rejects(act(a,v,'request'));
 let old=v;
 const operation=crypto.randomUUID();
 v=await act(b,v,'request',null,operation);assert.equal(v.status,'requested');assert.equal(v.awaiting_id,a);
 const retry=await act(b,old,'request',null,operation);assert.equal(retry.version,v.version);
 await assert.rejects(act(b,old,'withdraw'));
 await assert.rejects(act(b,v,'accept'));
 v=await act(a,v,'propose','2030-12-01T18:00:00Z');assert.equal(v.awaiting_id,b);
 await assert.rejects(act(a,v,'accept'));
 v=await act(b,v,'accept');assert.equal(v.status,'scheduled');assert.ok(v.scheduled_for);
 v=await act(a,v,'complete');assert.equal(v.status,'completed');assert.ok(v.completed_at);
 v=await act(b,v,'undo');assert.equal(v.status,'scheduled');assert.equal(v.completed_at,null);
 v=await act(b,v,'complete');assert.equal(v.status,'completed');
 let custom=(await offer(b,crypto.randomUUID(),a,null,'Une balade à deux')).rows[0];
 custom=await act(a,custom,'open');custom=await act(a,custom,'request');
 custom=await act(a,custom,'withdraw');assert.equal(custom.status,'opened');
 custom=await act(a,custom,'request');custom=await act(b,custom,'later');assert.equal(custom.status,'opened');
 custom=await act(a,custom,'request');custom=await act(b,custom,'complete');assert.equal(custom.status,'completed');
 custom=await act(a,custom,'undo');assert.equal(custom.status,'requested');
 custom=await act(a,custom,'withdraw');custom=await act(b,custom,'cancel');assert.equal(custom.status,'cancelled');
 await assert.rejects(act(a,custom,'request'));
 const other=(await offer(c,crypto.randomUUID(),d)).rows[0];
 assert.equal(await count(a,'couple_vouchers'),2);assert.equal(await count(c,'couple_vouchers'),1);
 await assert.rejects(act(a,other,'open'));
 const events=(await asUser(a,'select * from public.couple_voucher_events where voucher_id=$1',[id])).rows;
 assert.ok(events.some(e=>e.action==='propose'&&e.proposed_for));
 assert.equal(events.filter(e=>e.action==='request').length,1);
 const jobs=(await db.query("select * from public.wedding_notification_queue where event='voucher'")).rows;
 assert.ok(jobs.length>0);assert.ok(jobs.every(j=>j.entry_uuid===null&&j.voucher_event_id));
 await assert.rejects(asUser(b,'select * from public.wedding_notification_queue'));
 console.log('Voucher RPC / RLS tests passed: templates, custom, lifecycle, retries, stale versions, outsider, second couple, outbox.');
} finally {await db.close();}
