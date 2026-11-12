const test = require('node:test');
const assert = require('node:assert/strict');
const {assertMember, validate, canEdit, serialize} = require('../cloud/policy');
const members = [{id:'a',name:'Alyssa'},{id:'f',name:'Faris'}];
const letter = {id:'1',kind:'letter',authorId:'f',fields:{title:'Pour toi',body:'Secret',recipientId:'a',openAt:'2027-01-23T07:00:00Z'}};
test('denies anonymous, outsiders, and incorrectly configured roles', () => {
  for (const id of [null,'intruder']) assert.throws(()=>assertMember(id,members));
  assert.throws(()=>assertMember('a',[...members,{id:'x',name:'X'}]));
  assert.doesNotThrow(()=>assertMember('a',members));
});
test('recipient cannot receive body before opening, including export', () => {
  assert.equal(serialize(letter,'a',new Date('2027-01-23T06:59:59Z')).fields.body,undefined);
  assert.equal(serialize(letter,'a',new Date('2027-01-23T07:00:00Z')).fields.body,'Secret');
  assert.equal(serialize(letter,'f',new Date('2026-01-01')).fields.body,'Secret');
  assert.equal(serialize(letter,'x'),null);
});
test('recipient cannot edit author letter; dreams can be shared', () => {
  assert.equal(canEdit(letter,'a'),false);
  assert.equal(canEdit(letter,'f'),true);
  assert.equal(canEdit({...letter,kind:'dream'},'a'),true);
});
test('ignores client availability and derives recipient name server-side', () => {
  const fields=validate('letter',{...letter.fields,recipient:'Fake',available:true},members,'f');
  assert.equal(fields.recipient,'Alyssa');
  assert.equal(fields.available,undefined);
  assert.throws(()=>validate('letter',{...letter.fields,openAt:'nonsense'},members,'f'));
  assert.throws(()=>validate('letter',{...letter.fields,recipientId:'x'},members,'f'));
});
test('validates payloads and stamps thoughts with server time', () => {
  assert.throws(()=>validate('unknown',{},members,'a'));
  assert.throws(()=>validate('memory',{title:'Photo',photo:'https://external/image'},members,'a'));
  assert.throws(()=>validate('dream',{title:' ',done:true},members,'a'));
  assert.throws(()=>validate('dream',{title:'Rêve',done:'yes'},members,'a'));
  const thought=validate('thought',{title:'Fake',sentAt:'yesterday'},members,'a',new Date('2027-01-01Z'));
  assert.equal(thought.sentAt,'2027-01-01T00:00:00.000Z');
});

test('multi-photo albums preserve order and legacy photos, including removal', () => {
  const first='data:image/jpeg;base64,YQ==',second='data:image/png;base64,Yg==';
  assert.deepEqual(validate('memory',{title:'Album',photos:[second,first]},members,'a').photos,[second,first]);
  assert.equal(validate('memory',{title:'Album',photos:[second,first]},members,'a').photo,second);
  assert.deepEqual(validate('memory',{title:'Ancien',photo:first},members,'a').photos,[first]);
  assert.deepEqual(validate('memory',{title:'Retiré',photo:first,photos:[]},members,'a').photos,[]);
  assert.throws(()=>validate('memory',{title:'Trop',photos:Array(9).fill(first)},members,'a'));
  assert.throws(()=>validate('memory',{title:'Invalide',photos:'not an array'},members,'a'));
  assert.throws(()=>validate('memory',{title:'Privé',photos:['https://public/image.jpg']},members,'a'));
  const big='data:image/jpeg;base64,'+'a'.repeat(800000);
  assert.throws(()=>validate('memory',{title:'Taille',photos:Array(6).fill(big)},members,'a'));
});
test('open-when and personal dua belong to author and recipient, without date locks', () => {
  for (const kind of ['openWhen','dua']) {
    const data=validate(kind,{title:'Un jour difficile',body:'Mes propres mots',recipientId:'a',recipient:'Fake',available:true},members,'f');
    const e={id:'1',kind,authorId:'f',fields:data};
    assert.equal(data.recipient,'Alyssa');
    assert.equal(serialize(e,'a',new Date('2000-01-01')).fields.body,'Mes propres mots');
    assert.equal(serialize(e,'x'),null);
    assert.equal(canEdit(e,'a'),false);
    assert.equal(canEdit(e,'f'),true);
    assert.throws(()=>validate(kind,{title:'Test',body:' ',recipientId:'a'},members,'f'));
  }
});
test('happiness has a real calendar date and belongs to its author', () => {
  const fields={title:'Notre balade',date:'2028-02-29',gratitude:true};
  assert.equal(validate('happiness',fields,members,'a').gratitude,true);
  for(const date of ['2027-02-29','2027-13-12','2027-01-99']) assert.throws(()=>validate('happiness',{...fields,date},members,'a'));
  assert.throws(()=>validate('happiness',{...fields,gratitude:'yes'},members,'a'));
  assert.equal(canEdit({kind:'happiness',authorId:'a'},'f'),false);
});
test('intentions require a concrete action and can be edited together', () => {
  assert.throws(()=>validate('intention',{title:'Douceur',action:' '},members,'a'));
  assert.equal(validate('intention',{title:'Douceur',action:'S’écouter',done:true},members,'a').action,'S’écouter');
  assert.equal(validate('intention',{title:'Douceur',action:'S’écouter',done:true},members,'a').done,undefined);
  assert.equal(canEdit({kind:'intention',authorId:'a'},'f'),true);
});
test('V1 clients cannot accidentally erase an album or read unknown kinds', () => {
  const {visibleToClient,assertAlbumVersion}=require('../cloud/policy');
  assert.equal(visibleToClient({kind:'dua'},undefined),false);
  assert.equal(visibleToClient({kind:'memory'},undefined),true);
  assert.equal(visibleToClient({kind:'dua'},2),true);
  assert.throws(()=>assertAlbumVersion({kind:'memory',fields:{photos:['one','two']}},undefined));
  assert.doesNotThrow(()=>assertAlbumVersion({kind:'memory',fields:{photos:['one','two']}},2));
});
