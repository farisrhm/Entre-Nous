'use strict';
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const express = require('express');
const {ParseServer} = require('parse-server');
const Parse = require('parse/node');
const {MongoMemoryServer} = require('mongodb-memory-server-core');
const {MongoClient} = require('mongodb');
const root = path.resolve(__dirname, '..');
const state = path.resolve(process.env.WEDDING_DATA_DIR || path.join(root,'.local'));
const configPath = path.join(state,'server.json');
if (!fs.existsSync(configPath)) throw new Error('Lancer npm run setup avant npm start.');
const config = JSON.parse(fs.readFileSync(configPath));
const port = Number(process.env.PORT || 1337);
const host = process.env.HOST || '127.0.0.1';
const internalURL = `http://127.0.0.1:${port}/parse`;
const photos = path.join(state,'photos');
fs.mkdirSync(photos,{recursive:true,mode:0o700});
fs.mkdirSync(path.join(state,'mongo'),{recursive:true,mode:0o700});
process.env.WEDDING_PRIVATE_PHOTOS = photos;
let mongo, api, listener;
async function bootstrap(uri) {
  Parse.initialize(config.appId, config.clientKey, config.masterKey);
  Parse.serverURL = internalURL;
  let role = await new Parse.Query(Parse.Role).equalTo('name','couple').first({useMasterKey:true});
  if (!role) role = new Parse.Role('couple', new Parse.ACL());
  for (const member of config.members) {
    let user = await new Parse.Query(Parse.User).equalTo('username',member.username).first({useMasterKey:true});
    if (!user) {
      user = new Parse.User();
      user.set({...member});
      user.setACL(new Parse.ACL());
      await user.save(null,{useMasterKey:true});
    }
    role.getUsers().add(user);
  }
  await role.save(null,{useMasterKey:true});
  const schema = new Parse.Schema('WeddingEntry');
  try { await schema.get(); } catch (e) {
    if (e.code !== 103) throw e;
    await schema.addString('key').addString('entryId').addString('kind').addString('authorId').addObject('fields').save();
  }
  const deny = {find:{},get:{},count:{},create:{},update:{},delete:{},addField:{}};
  await new Parse.Schema('WeddingEntry').setCLP(deny).update();
  await new Parse.Schema('_Role').setCLP(deny).update();
  await new Parse.Schema('_User').setCLP(deny).update();
  const client = await MongoClient.connect(uri);
  try { await client.db().collection('WeddingEntry').createIndex({key:1},{unique:true}); }
  finally { await client.close(); }
}
async function main() {
  mongo = await MongoMemoryServer.create({
    binary:{version:'8.0.17',downloadDir:path.join(state,'binaries')},
    instance:{ip:'127.0.0.1',dbPath:path.join(state,'mongo'),dbName:'wedding',storageEngine:'wiredTiger'}
  });
  const uri = mongo.getUri('wedding');
  api = new ParseServer({databaseURI:uri,appId:config.appId,clientKey:config.clientKey,masterKey:config.masterKey,
    serverURL:internalURL,publicServerURL:process.env.WEDDING_SERVER_URL || internalURL,
    cloud:path.join(root,'cloud/main.js'),allowClientClassCreation:false,
    maxUploadSize:'1mb',maxLimit:100,sessionLength:31536000,
    filesAdapter:undefined,logLevel:'error',enableAnonymousUsers:false,
    fileUpload:{enableForPublic:false,enableForAnonymousUser:false,enableForAuthenticatedUser:false}
  });
  await api.start();
  const app = express();
  app.disable('x-powered-by');
  let ready = false;
  app.get('/health',(_req,res)=>res.status(ready?200:503).json({ready}));
  app.use('/parse',api.app);
  async function member(req,res,next) {
    try {
      const token = req.get('X-Parse-Session-Token');
      if (!token) return res.sendStatus(401);
      const response = await fetch(internalURL+'/users/me',{headers:{'X-Parse-Application-Id':config.appId,'X-Parse-Client-Key':config.clientKey,'X-Parse-Session-Token':token}});
      if (!response.ok) return res.sendStatus(401);
      const user = await response.json();
      const role = await new Parse.Query(Parse.Role).equalTo('name','couple').first({useMasterKey:true});
      const members = await role.getUsers().query().find({useMasterKey:true});
      if (members.length!==2 || !members.some(m=>m.id===user.objectId)) return res.sendStatus(403);
      next();
    } catch { res.sendStatus(503); }
  }
  app.post('/private-photos',member,express.raw({type:['image/jpeg','image/png','image/webp'],limit:'20mb'}),(req,res)=>{
    const bytes=req.body;
    if (!Buffer.isBuffer(bytes) || !bytes.length) return res.sendStatus(415);
    const mime = bytes.subarray(0,3).equals(Buffer.from([255,216,255]))?'image/jpeg':
      bytes.subarray(0,8).equals(Buffer.from([137,80,78,71,13,10,26,10]))?'image/png':
      bytes.subarray(0,4).toString()==='RIFF' && bytes.subarray(8,12).toString()==='WEBP'?'image/webp':null;
    if (!mime || mime!==req.get('Content-Type')) return res.sendStatus(415);
    const id=crypto.randomUUID();
    fs.writeFileSync(path.join(photos,id),bytes,{flag:'wx',mode:0o600});
    fs.writeFileSync(path.join(photos,id+'.json'),JSON.stringify({mime,size:bytes.length}),{flag:'wx',mode:0o600});
    res.status(201).json({source:'private-photo:'+id});
  });
  app.get('/private-photos/:id',member,(req,res)=>{
    if (!/^[0-9a-f-]{36}$/.test(req.params.id)) return res.sendStatus(404);
    const file=path.join(photos,req.params.id);
    if (!fs.existsSync(file+'.json')) return res.sendStatus(404);
    const meta=JSON.parse(fs.readFileSync(file+'.json'));
    res.set({'Content-Type':meta.mime,'Cache-Control':'private, no-store','X-Content-Type-Options':'nosniff'});
    res.sendFile(file);
  });
  app.use((err,_req,res,_next)=>res.status(err.type==='entity.too.large'?413:500).json({error:'Requête refusée.'}));
  listener=app.listen(port,host,async()=>{
    try { await bootstrap(uri); ready=true; console.log(`Serveur prêt : http://${host}:${port}/health`); }
    catch(e) { console.error('Initialisation impossible:',e.message); await stop(); process.exitCode=1; }
  });
  listener.on('error',async e=>{console.error(e.message);await stop();process.exitCode=1;});
}
let stopping=false;
async function stop(){
  if(stopping)return; stopping=true;
  if(listener)await new Promise(resolve=>listener.close(resolve));
  if(api)await api.handleShutdown();
  if(mongo)await mongo.stop({doCleanup:false});
}
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,async()=>{await stop();process.exit(0);});
main().catch(async e=>{console.error(e.message);await stop();process.exitCode=1;});
