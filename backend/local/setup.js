'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '..');
const state = path.join(root, '.local');
fs.mkdirSync(state, {recursive:true, mode:0o700});
const target = path.join(state, 'server.json');
if (!fs.existsSync(target)) {
  const secret = () => crypto.randomBytes(32).toString('base64url');
  fs.writeFileSync(target, JSON.stringify({appId:'jusqua-nous-local', clientKey:secret(), masterKey:secret(), members:[
    {username:'faris', displayName:'Faris', password:secret()},
    {username:'alyssa', displayName:'Alyssa', password:secret()}
  ]},null,2)+'\n', {mode:0o600, flag:'wx'});
}
const config = JSON.parse(fs.readFileSync(target));
const url = process.env.WEDDING_SERVER_URL || 'http://localhost:1337/parse';
const parsed = new URL(url);
if (!['http:', 'https:'].includes(parsed.protocol) || parsed.username || parsed.password) throw new Error('URL serveur invalide');
fs.writeFileSync(path.join(root,'../config/local.json'), JSON.stringify({PARSE_APP_ID:config.appId,PARSE_CLIENT_KEY:config.clientKey,PARSE_SERVER_URL:url,LOCAL_SERVER:true},null,2)+'\n',{mode:0o600});
fs.writeFileSync(path.join(state,'codes-prives.txt'), config.members.map(m => `${m.displayName}\n${m.password}`).join('\n\n')+'\n',{mode:0o600});
console.log('Configuration prête : config/local.json. Codes privés : backend/.local/codes-prives.txt (ne pas partager publiquement).');
