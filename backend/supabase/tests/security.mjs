// Run with PGLITE_MODULE pointing at an installed @electric-sql/pglite module.
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const {PGlite} = await import(process.env.PGLITE_MODULE || '@electric-sql/pglite');
const db = new PGlite();
const a='b52d499a-f6a9-4772-ad91-149d853e36e5', b='86828ab6-34fb-4956-b54c-607d945cb445';
const outsider='11111111-1111-4111-8111-111111111111';
await db.exec(`
create role anon; create role authenticated; create role service_role bypassrls;
create schema auth; create schema storage;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
create table storage.objects(id uuid default gen_random_uuid(),bucket_id text,name text);
create function storage.foldername(text) returns text[] language sql as $$select string_to_array($1,'/')$$;
grant usage on schema auth, storage to anon,authenticated;
grant all on storage.objects to anon,authenticated;
alter table storage.objects enable row level security;
-- Simulate an unrelated older, permissive Storage policy: guards must still protect our bucket.
create policy existing_open_policy on storage.objects for all to public using(true) with check(true);
insert into auth.users values ('${a}'),('${b}'),('${outsider}');
`);
for(const filename of ['001_init_wedding.sql','002_private_storage_atomic.sql']) {
  const sql=await readFile(new URL('../migrations/'+filename,import.meta.url),'utf8');
  await db.exec(sql.replace('create extension if not exists pgcrypto;',''));
}
await db.exec('grant select on public.wedding_entries to authenticated;');
await db.query("insert into public.couple_members(couple_id,user_id,display_name) values ('couple',$1,'Alyssa'),('couple',$2,'Faris')",[a,b]);
const save=async(actor,id,kind='dua',fields={title:'Pour toi',body:'Secret',recipientId:b},version=3)=>{
  return db.query('select public.wedding_save_atomic($1,$2,$3,$4,$5)',[actor,kind,id,fields,version]);
};
async function asUser(id,sql,args=[]) {
  await db.exec('begin; set local role authenticated;');
  try {await db.query("select set_config('request.jwt.claim.sub',$1,true)",[id]);const r=await db.query(sql,args);await db.exec('commit');return r;}
  catch(e){await db.exec('rollback');throw e;}
}
try {
  await save(a,'letter','letter',{title:'Plus tard',body:'SECRET',recipientId:b,openAt:'2099-01-01T00:00:00Z'});
  await assert.rejects(asUser(outsider,'select * from public.wedding_entry_debug'));
  assert.equal((await asUser(a,'select * from public.wedding_entries')).rows.length,0);
  await assert.rejects(asUser(b,"select public.wedding_save_atomic($1,'dua','bad','{}',3)",[a]));
  await assert.rejects(save(outsider,'bad'));
  await save(a,'owned');
  await assert.rejects(save(b,'owned'));
  await assert.rejects(db.query("select public.wedding_delete_atomic($1,'dua','owned')",[b]));
  const row=(await db.query("select * from public.wedding_entries where entry_id='owned'")).rows[0];
  assert.equal(row.author_id,a);
  await save(a,'shared','intention',{title:'Notre foyer',action:'Écouter',createdAt:'2026-01-01T00:00:00Z'});
  await save(b,'shared','intention',{title:'Notre foyer',action:'Partager',createdAt:'2027-01-01T00:00:00Z'});
  const shared=(await db.query("select * from public.wedding_entries where entry_id='shared'")).rows[0];
  assert.equal(shared.author_id,a);assert.equal(shared.fields.createdAt,'2026-01-01T00:00:00Z');
  const path=a+'/'+ 'a'.repeat(32)+'.jpeg';
  await asUser(a,"insert into storage.objects(bucket_id,name) values ('wedding-photos',$1)",[path]);
  assert.equal((await asUser(b,"select * from storage.objects where bucket_id='wedding-photos'")).rows.length,1);
  assert.equal((await asUser(outsider,"select * from storage.objects where bucket_id='wedding-photos'")).rows.length,0);
  await assert.rejects(asUser(b,"insert into storage.objects(bucket_id,name) values ('wedding-photos',$1)",[path]));
  await assert.rejects(asUser(outsider,"insert into storage.objects(bucket_id,name) values ('wedding-photos',$1)",[outsider+'/'+ 'b'.repeat(32)+'.jpeg']));
  assert.equal((await asUser(a,"delete from storage.objects where bucket_id='wedding-photos' returning *")).rows.length,0);
  const source='storage:wedding-photos/'+path;
  await save(a,'album','memory',{title:'Album',photos:[source],photo:source});
  await assert.rejects(save(b,'album','memory',{title:'Old app',photos:[]},2));
  await assert.rejects(save(a,'missing','memory',{title:'Missing',photos:[source.replace('aaaa','bbbb')]}));
  const results=await Promise.allSettled([save(a,'same'),save(b,'same')]);
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  console.log('SQL: migrations, private view/RLS, outsider rejection, authorship, immutable photos, legacy protection and conflicting saves passed.');
} finally {await db.close();}
