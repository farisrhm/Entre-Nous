'use strict';
const legacyKinds = new Set(['memory', 'letter', 'dream', 'promise', 'thought']);
const kinds = new Set([...legacyKinds, 'openWhen', 'happiness', 'dua', 'intention']);
const personalKinds = new Set(['letter', 'promise', 'thought', 'openWhen', 'happiness', 'dua']);
function assertMember(userId, members) {
  if (!userId || members.length !== 2 || !members.some(m => m.id === userId)) {
    throw new Error('Cet espace est réservé aux deux membres du couple.');
  }
}
function validate(kind, fields, members, userId, now = new Date()) {
  if (!kinds.has(kind) || !fields || typeof fields !== 'object' || Array.isArray(fields)) throw new Error('Contenu invalide.');
  const text = (key, max, required = false) => {
    const value = fields[key] ?? '';
    if (typeof value !== 'string' || value.length > max || (required && !value.trim())) throw new Error(`Champ invalide : ${key}`);
    return value.trim();
  };
  const clean = {title: text('title', 160, true)};
  if (['memory','letter','promise','openWhen','happiness','dua','intention'].includes(kind)) clean.body = text('body', 20000, ['letter','openWhen','dua'].includes(kind));
  if (kind === 'memory') {
    clean.date = text('date', 100);
    // Legacy clients send one photo; the first item stays the cover.
  const photos = fields.photos === undefined ? (text('photo',12000000) ? [text('photo',12000000)] : []) : fields.photos;
    if (!Array.isArray(photos) || photos.length > 8) throw new Error('Un album contient au maximum 8 photos.');
  if (photos.some(p => typeof p !== 'string' || p.length > 12000000 || !/^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/.test(p))) throw new Error('Les photos doivent être importées depuis la photothèque.');
  if (photos.reduce((n,p)=>n+p.length,0) > 50000000) throw new Error('Cet album est trop volumineux.');
    clean.photos = [...photos];
    clean.photo = photos[0] || '';
  }
  if (kind === 'dream') {
    if (typeof fields.done !== 'boolean') throw new Error('État du rêve invalide.');
    clean.done = fields.done;
  }
  if (['letter','openWhen','dua'].includes(kind)) {
    const recipient = members.find(m => m.id === fields.recipientId);
    if (!recipient) throw new Error('Destinataire invalide.');
    clean.recipientId = recipient.id;
    clean.recipient = recipient.name;
  }
  if (kind === 'letter') {
    const openAt = new Date(text('openAt', 40, true));
    if (!Number.isFinite(openAt.getTime())) throw new Error('Date invalide.');
    clean.openAt = openAt.toISOString();
  }
  if (kind === 'happiness') {
    const date = text('date',10,true);
    const parsed = new Date(`${date}T12:00:00Z`);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !Number.isFinite(parsed.getTime()) || parsed.toISOString().slice(0,10)!==date) throw new Error('Date du bonheur invalide.');
    if (typeof fields.gratitude !== 'boolean') throw new Error('Gratitude invalide.');
    clean.date=date; clean.gratitude=fields.gratitude;
  }
  if (kind === 'intention') clean.action=text('action',1000,true);
  if (!legacyKinds.has(kind)) clean.createdAt=now.toISOString();
  if (kind === 'promise') clean.title = members.find(m => m.id === userId).name;
  if (kind === 'thought') { clean.title = 'Je pense à toi'; clean.sentAt = now.toISOString(); }
  return clean;
}
function canEdit(entry, userId) {
  return !personalKinds.has(entry.kind) || entry.authorId === userId;
}
function serialize(entry, userId, now = new Date()) {
  const fields = {...entry.fields};
  if (['letter','openWhen','dua'].includes(entry.kind)) {
    if (entry.authorId !== userId && fields.recipientId !== userId) return null;
  }
  if (entry.kind === 'letter') {
    fields.available = now.getTime() >= new Date(fields.openAt).getTime();
    if (entry.authorId !== userId && !fields.available) delete fields.body;
  }
  return {...entry, fields};
}
function visibleToClient(entry, schemaVersion) {
  return schemaVersion >= 2 || legacyKinds.has(entry.kind);
}
function assertAlbumVersion(entry, schemaVersion) {
  if (entry.kind === 'memory' && (entry.fields.photos?.length || 0) > 1 && !(schemaVersion >= 2)) {
    throw new Error('Mets l’application à jour pour modifier un album de plusieurs photos.');
  }
}
module.exports = {assertMember, validate, canEdit, serialize, visibleToClient, assertAlbumVersion};
