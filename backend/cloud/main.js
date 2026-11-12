'use strict';
const policy = require('./policy');
const CLASS = 'WeddingEntry';
const master = {useMasterKey: true};
const denied = message => new Parse.Error(Parse.Error.OPERATION_FORBIDDEN, message);
async function membersFor(request) {
  if (!request.user) throw denied('Connexion requise.');
  const role = await new Parse.Query(Parse.Role).equalTo('name', 'couple').first(master);
  if (!role) throw denied('Le rôle couple doit être configuré dans Back4App.');
  const users = await role.getUsers().query().limit(3).find(master);
  const members = users.map(u => ({id: u.id, name: u.get('displayName') || u.get('username')}));
  policy.assertMember(request.user.id, members);
  return members;
}
function keyFrom(params) {
  if (typeof params.id !== 'string' || !/^[a-zA-Z0-9_-]{1,100}$/.test(params.id)) throw denied('Identifiant invalide.');
  return `${params.kind}:${params.id}`;
}
function entryFrom(object) {
  return {id: object.get('entryId'), kind: object.get('kind'), fields: object.get('fields'), authorId: object.get('authorId')};
}
// Direct REST queries and writes must never bypass the release policy.
for (const event of ['beforeFind', 'beforeSave', 'beforeDelete']) {
  Parse.Cloud[event](CLASS, request => { if (!request.master) throw denied('Utiliser les fonctions de cet espace.'); });
}
// A client must never add itself to the private couple role.
for (const event of ['beforeSave', 'beforeDelete']) {
  Parse.Cloud[event](Parse.Role, request => { if (!request.master) throw denied('Administration uniquement.'); });
}
Parse.Cloud.define('weddingList', async request => {
  const members = await membersFor(request);
  const rows = [];
  let cursor;
  // Paginate instead of silently losing memories after Parse's default limit.
  do {
    const query = new Parse.Query(CLASS).ascending('objectId').limit(100);
    if (cursor) query.greaterThan('objectId', cursor);
    const batch = await query.find(master);
    rows.push(...batch);
    cursor = batch.length === 100 ? batch[batch.length - 1].id : undefined;
  } while (cursor);
  rows.sort((a, b) => a.createdAt - b.createdAt);
  const now = new Date();
  return {userId: request.user.id, members, entries: rows.map(entryFrom).filter(e => policy.visibleToClient(e, request.params.schemaVersion)).map(e => policy.serialize(e, request.user.id, now)).filter(Boolean)};
}, {requireUser: true});
Parse.Cloud.define('weddingSave', async request => {
  const members = await membersFor(request);
  const {kind, id, fields} = request.params;
  const key = keyFrom(request.params);
  const clean = policy.validate(kind, fields, members, request.user.id);
  if (kind === 'promise' && id !== `promise-${request.user.id}`) throw denied('Chacun écrit ses propres promesses.');
  let row = await new Parse.Query(CLASS).equalTo('key', key).first(master);
  if (row && !policy.canEdit(entryFrom(row), request.user.id)) throw denied('Seul l’auteur peut modifier ce contenu.');
  if (row) {
    policy.assertAlbumVersion(entryFrom(row), request.params.schemaVersion);
    if (clean.createdAt) clean.createdAt = row.get('fields').createdAt || row.createdAt.toISOString();
  }
  if (!row) {
    row = new Parse.Object(CLASS);
    row.set({key, entryId: id, kind, authorId: request.user.id});
    row.setACL(new Parse.ACL());
  }
  row.set('fields', clean);
  await row.save(null, master);
  return {id};
}, {requireUser: true});
Parse.Cloud.define('weddingDelete', async request => {
  await membersFor(request);
  const row = await new Parse.Query(CLASS).equalTo('key', keyFrom(request.params)).first(master);
  if (row) {
    if (!policy.canEdit(entryFrom(row), request.user.id)) throw denied('Seul l’auteur peut supprimer ce contenu.');
    await row.destroy(master);
  }
  return {deleted: true};
}, {requireUser: true});
