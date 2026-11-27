import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
const {PGlite}=await import(process.env.PGLITE_MODULE||'@electric-sql/pglite');
const db=new PGlite();
const a='aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',b='bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',outsider='cccccccc-cccc-4ccc-8ccc-cccccccccccc';
await db.exec(`create role anon;create role authenticated;create schema auth;
create table auth.users(id uuid primary key);
create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
grant usage on schema auth to authenticated,anon;
insert into auth.users values('${a}'),('${b}'),('${outsider}');`);
const sql=await readFile(new URL('../migrations/001_init_wedding.sql',import.meta.url),'utf8');await db.exec(sql.replace('create extension if not exists pgcrypto;',''));
const storage=await readFile(new URL('../migrations/002_private_storage_atomic.sql',import.meta.url),'utf8');await db.exec(storage.slice(storage.indexOf('create or replace function public.is_wedding_member()'),storage.indexOf('insert into storage.buckets')));
const migration=await readFile(new URL('../migrations/006_memory_reactions.sql',import.meta.url),'utf8');await db.exec(migration);await db.exec(migration);
await db.exec(`insert into public.couple_members(couple_id,user_id,display_name) values('couple','${a}','A'),('couple','${b}','B');
insert into public.wedding_entries(key,entry_id,kind,author_id,fields) values('memory:m1','m1','memory','${a}','{"title":"Original","photos":["photo"]}'),('letter:l1','l1','letter','${a}','{}');`);
async function asUser(id,sql,args=[]){await db.exec('begin;set local role authenticated');try{await db.query("select set_config('request.jwt.claim.sub',$1,true)",[id]);const result=await db.query(sql,args);await db.exec('commit');return result.rows;}catch(e){await db.exec('rollback');throw e;}}
const set=(id,memory,emoji)=>asUser(id,'select public.set_memory_reaction($1,$2)',[memory,emoji]);
const list=id=>asUser(id,'select user_id,emoji from public.memory_reactions order by user_id');
try{
 await set(a,'m1','❤️');await set(b,'m1','🥰');assert.equal((await list(a)).length,2);
 await set(a,'m1','👍🏽');assert.deepEqual(await list(b),[{user_id:a,emoji:'👍🏽'},{user_id:b,emoji:'🥰'}]);
 await set(a,'m1','👍🏽');assert.equal((await list(a)).length,2);
 for(const emoji of ['👩‍❤️‍👨','🇩🇿','🇪🇸','1️⃣','🫶🏾','🏳️‍🌈'])await set(a,'m1',emoji);
 for(const emoji of ['','bonjour','❤️texte','❤️\n','🥰é','a'.repeat(129)])await assert.rejects(set(a,'m1',emoji));
 assert.equal((await list(outsider)).length,0);await assert.rejects(set(outsider,'m1','❤️'));await assert.rejects(set('','m1','❤️'));
 await assert.rejects(set(a,'missing','❤️'));await assert.rejects(set(a,'l1','❤️'));
 await assert.rejects(asUser(a,'delete from public.memory_reactions where user_id=$1',[b]));
 await assert.rejects(asUser(a,'update public.memory_reactions set emoji=$1',['🔥']));
 await set(a,'m1',null);assert.deepEqual(await list(b),[{user_id:b,emoji:'🥰'}]);
 assert.deepEqual((await db.query("select fields from public.wedding_entries where key='memory:m1'")).rows[0].fields,{title:'Original',photos:['photo']});
 await db.exec("delete from public.wedding_entries where key='memory:m1'");assert.equal((await list(b)).length,0);
 console.log('PASS: independent reactions, emoji sequences, membership, author isolation, idempotency, intact album and cascade deletion.');
}finally{await db.close();}
