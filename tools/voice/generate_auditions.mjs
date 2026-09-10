// Run with MINIMAX_API_KEY in the environment. No credentials are written.
import fs from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const out = path.join(root, 'assets/audio/voice_auditions');
const cache = path.join(root, 'assets/audio/voice_cache');
const key = process.env.MINIMAX_API_KEY;
if (!key) throw new Error('Set MINIMAX_API_KEY in the process environment.');
const host = 'https://api.minimaxi.com';
const model = 'speech-2.8-hd';
const hash = s => crypto.createHash('sha256').update(s.trim()).digest('hex');
const readJSON = async p => JSON.parse((await fs.readFile(p, 'utf8')).replace(/^\uFEFF/, ''));
await fs.mkdir(out, {recursive:true});
await fs.mkdir(cache, {recursive:true});
const manifestPath = path.join(out, 'manifest.json');
let manifest;
try { manifest = await readJSON(manifestPath); } catch { manifest = {model, samples:[], designs:[], failures:[]}; }
const save = () => fs.writeFile(manifestPath, JSON.stringify(manifest, null, 2));
async function api(endpoint, payload) {
  const r = await fetch(host + endpoint, {method:'POST', redirect:'error',
    headers:{Authorization:`Bearer ${key}`, 'Content-Type':'application/json'},
    body:JSON.stringify(payload), signal:AbortSignal.timeout(55000)});
  if (!r.ok) throw new Error(`MiniMax HTTP ${r.status}`);
  const result = await r.json();
  if (result.base_resp?.status_code !== 0) throw new Error(`MiniMax ${result.base_resp?.status_code}: ${result.base_resp?.status_msg}`);
  return result;
}
async function exists(p) { try { return (await fs.stat(p)).size > 1000; } catch { return false; } }
async function sample(id, title, voice, text, language='Chinese', settings={}, direction='') {
  const audio = path.join(out, id + '.mp3');
  const request = {model, text, stream:false, language_boost:language, output_format:'hex',
    voice_setting:{voice_id:voice,speed:1,vol:1,pitch:0,...settings},
    audio_setting:{sample_rate:32000,bitrate:128000,format:'mp3',channel:1}};
  const fingerprint = hash(JSON.stringify(request));
  const previous = manifest.samples.find(s=>s.id===id);
  if (previous?.fingerprint===fingerprint && await exists(audio)) return previous;
  console.log('Generating ' + id);
  let extra = {};
  // Use the installed MiniMax CLI for standard synthesis; direct API adds
  // documented emotion controls that mmx 1.0.15 does not expose.
  if (!settings.emotion) {
    const textPath = path.join(out, id + '.txt');
    await fs.writeFile(textPath, text);
    const cli = path.join(process.env.APPDATA, 'npm/node_modules/mmx-cli/dist/mmx.mjs');
    const args = [cli, 'speech', 'synthesize', '--text-file', textPath, '--voice', voice,
      '--model',model,'--speed',String(settings.speed??1),'--pitch',String(settings.pitch??0),
      '--language',language,'--out',audio,'--region','cn','--non-interactive','--quiet'];
    const run = spawnSync(process.execPath,args,{env:{...process.env,MINIMAX_REGION:'cn'},encoding:'utf8',timeout:55000,windowsHide:true});
    if (run.status!==0) throw new Error('mmx synthesis failed ('+id+'); exit '+run.status);
  } else {
    const result = await api('/v1/t2a_v2',request);
    if (!result.data?.audio || !/^[0-9a-f]+$/i.test(result.data.audio)) throw new Error('Invalid speech audio');
    await fs.writeFile(audio,Buffer.from(result.data.audio,'hex'));
    extra = result.extra_info || {};
  }
  if (!await exists(audio)) throw new Error('Empty speech output');
  const item = {id,title,voice_id:voice,language,text,direction,settings:request.voice_setting,
    path:'res://assets/audio/voice_auditions/'+id+'.mp3',fingerprint,...extra};
  manifest.samples=manifest.samples.filter(s=>s.id!==id);manifest.samples.push(item);await save();return item;
}
async function design(id,title,prompt) {
  let entry=manifest.designs.find(d=>d.id===id);
  if (entry) return entry.voice_id;
  console.log('Designing '+id);
  const text='嗯，接通了。你那边也安静下来了？我把文档打开。今天先改这一小段。';
  const result=await api('/v1/voice_design',{prompt,preview_text:text});
  if (!result.voice_id || !result.trial_audio) throw new Error('Voice design returned no preview');
  await fs.writeFile(path.join(out,id+'.mp3'),Buffer.from(result.trial_audio,'hex'));
  entry={id,title,prompt,voice_id:result.voice_id};manifest.designs.push(entry);
  manifest.samples.push({id,title,voice_id:result.voice_id,language:'Chinese',text,direction:prompt,
    path:'res://assets/audio/voice_auditions/'+id+'.mp3',settings:{},kind:'design_preview'});
  await save();return result.voice_id;
}
async function attempt(label,fn) {try{return await fn();}catch(e){console.log(label+': '+e.message);manifest.failures.push({label,error:e.message});await save();return null;}}

const comparison='嗯，接通了。你那边也安静下来了？我把文档打开。今天先改这一小段。';
for (const [id,title,voice] of [
 ['zh_warm','A · 温暖少女','Chinese (Mandarin)_Warm_Girl'],
 ['zh_gentle','B · 温柔学姐','Chinese (Mandarin)_Gentle_Senior'],
 ['zh_soft','C · 软软女孩','Chinese (Mandarin)_Soft_Girl'],
 ['zh_young','D · 少女原声','female-shaonv']]) {
 await attempt(id,()=>sample(id,title,voice,comparison,'Chinese',{},'Same text and speed: compare vocal identity.'));
}
const customA=await attempt('design_close',()=>design('design_close','E · 原创：清亮自然',
 '21岁成年女性，普通话自然标准，清亮但不尖细的年轻女声，中等偏高音区，音色干净，有一点松弛的鼻腔共鸣。像安静视频通话里熟悉的同龄人，近距离正常说话，轻快温暖，语尾自然落下，偶尔带一点自嘲的笑意。不要播音腔、客服腔、幼童感、刻意撒娇、耳语、气泡音或过重气声。'));
const customB=await attempt('design_low',()=>design('design_low','F · 原创：温润微低',
 '成年年轻女性，约22岁，普通话，音区中等略低，温润柔和但字头清楚，声音轻而有支撑，干净近讲。内向、有主见、带一点干幽默的书店女孩，在安静的线上自习通话中聊天。自然口语节奏，放松、不拖尾、不刻意卖萌。避免成熟播音主持感、忧郁、性感耳语、过度气声及幼态高尖音。'));
const lead=customA || 'Chinese (Mandarin)_Warm_Girl';
await attempt('zh_calm',()=>sample('zh_calm','G · 安静开工',lead,
 '我把文档打开了。<#0.35#>你忙你的，我也改两行。','Chinese',{speed:0.96,emotion:'calm'},'Calm, normal speaking voice; a short intentional pause.'));
await attempt('zh_tease',()=>sample('zh_tease','H · 翻车后嘴硬',lead,
 '我这次真的不打游戏了。真的。<#0.3#>你按啊。','Chinese',{speed:1.04,emotion:'happy'},'Brighter comic timing, without shouting.'));
await attempt('zh_embarrassed',()=>sample('zh_embarrassed','I · 认真后自己破功',lead,
 '海风一吹，纸边就翘起来，像有人偷偷翻了一页。<#0.4#>啊，这句说出来有点尴尬。当我没说。','Chinese',{speed:1,emotion:'calm'},'Contrast a sincere image with an embarrassed retreat.'));
for (const [id,title,voice,language,text] of [
 ['en_same','EN · 同一音色',lead,'English',"Oh, we're connected. I'll open my draft. You do your thing; I'll work on this paragraph."],
 ['ja_same','JP · 同じ声',lead,'Japanese','あ、つながった。私も原稿を開くね。そっちはそっちの作業をどうぞ。私はこの段落を直してる。'],
 ['en_native','EN · English voice comparison','English_Graceful_Lady','English',"Oh, we're connected. I'll open my draft. You do your thing; I'll work on this paragraph."],
 ['ja_native','JP · 日本語音色比較','Japanese_CalmLady','Japanese','あ、つながった。私も原稿を開くね。そっちはそっちの作業をどうぞ。私はこの段落を直してる。']]) {
 await attempt(id,()=>sample(id,title,voice,text,language,{},'Brief multilingual comparison; audition copy, not a script translation.'));
}
// First playable sample pack: selected real, token-free beats. Exact-text hashes
// prevent an old clip being played after a script edit by another session.
const script=await readJSON(path.join(root,'data/dialogue/scripted_nodes.json'));
const nodes=Array.isArray(script.nodes)?script.nodes:Object.values(script.nodes||{});
const game={version:1,provisional_voice_id:lead,model,clips:{}};
let count=0;
for (const node of nodes) {
 if (!['ep00_01','ep00_02','ep00_03','ep00_close','FOCUS_START_001'].includes(node.id)) continue;
 for (const [i,chunk] of String(node.line||'').split('\n\n').entries()) {
  const text=chunk.trim(); if (!text || /[{}（）]/.test(text) || count>=10) continue;
  const item=await attempt('game_'+node.id+'_'+i,()=>sample('game_'+node.id+'_'+i,
   '游戏片段 · '+node.id+' / '+(i+1),lead,text,'Chinese',{},'Actual authored beat; provisional voice until owner picks.'));
  if (!item) continue;
  const digest=hash(text); const filename=digest+'.mp3';
  await fs.copyFile(path.join(out,item.id+'.mp3'),path.join(cache,filename));
  game.clips[digest]={path:'res://assets/audio/voice_cache/'+filename,text,voice_id:lead,node_id:node.id};count++;
 }
}
await fs.writeFile(path.join(root,'data/dialogue/voice_manifest.json'),JSON.stringify(game,null,2));
await save();
console.log('DONE: '+manifest.samples.length+' auditions / '+count+' game beats.');
