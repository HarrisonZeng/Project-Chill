import fs from 'node:fs/promises';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../..');
const dir=path.join(root,'assets/audio/voice_auditions');
const mp=path.join(dir,'manifest.json');
const manifest=JSON.parse((await fs.readFile(mp,'utf8')).replace(/^\uFEFF/,''));
const key=process.env.MINIMAX_API_KEY;
if(!key)throw Error('MINIMAX_API_KEY missing');
const text='我这次真的不打游戏了。真的。你按啊。';
const common='中文二次元游戏的成年少女角色配音，20岁左右。中文母语配音演员，普通话纯正，汉语声调准确，连读自然，没有外国口音或刻意方言。是在接对面人的话，有角色表演和鲜活反应，不能像念作文、朗读文章、播音报幕或客服。少女声线可爱悦耳，避免儿童奶音。';
const variants=[
 {id:'r2_a',title:'二轮 A · 元气俏皮 / 清脆',prompt:common+'明亮清脆的中高音，声音位置靠前，轻盈有弹性，带笑意和一点俏皮鼻音。像恋爱喜剧动画里嘴硬又可爱的女主角：反应快，音高起伏鲜明，重音灵活，句尾轻巧。先认真发誓，再心虚补一句，最后忍不住催对方。元气而不大喊，甜但不腻。',extra:'诶？我没偷懒。我是在想下一句。好吧，刚才确实看了一眼手机。',emotion:'happy',speed:1.04},
 {id:'r2_b',title:'二轮 B · 元气俏皮 / 甜亮',prompt:common+'甜亮柔韧的高音少女声，比日常聊天更有动漫角色辨识度。清甜的头腔共鸣，字头轻巧，语气有小跳跃，尾音会短促扬起再收住。笑意明显，有点小得意和被抓包后的嘴硬，像在和同龄搭子斗嘴。每句话有不同情绪，不要均匀抑扬顿挫，不要台词朗诵。',extra:'你看，我写完了。就一小段，但它今天没有被我删掉。这个得算数吧？',emotion:'happy',speed:1.0},
 {id:'r2_c',title:'二轮 C · 慵懒可爱 / 软糯',prompt:common+'柔软微糯的中高音少女声，带一点轻巧鼻腔共鸣，音量轻但发音有支撑。松弛、懒洋洋、可爱，像动画里靠在椅背上、眯着眼开小玩笑的年轻女主。说话稍慢，词组之间留小空隙，句尾软软收住，吐槽时忽然变清晰。软而不虚，不能气声耳语、性感、成熟低沉或昏昏欲睡。',extra:'再靠一会儿，就一会儿。嗯，好了。我坐起来了，文档也打开了。',emotion:'calm',speed:0.96},
 {id:'r2_d',title:'二轮 D · 慵懒可爱 / 小傲娇',prompt:common+'有二次元辨识度的年轻少女声，中高音区，柔滑略带鼻音，音色甜而清楚。悠闲慢半拍，轻轻拖一个语气尾巴，然后干脆收音。懒懒的可爱里带一点小傲娇、理直气壮和干幽默，像熟悉的同龄朋友随口逗人。语气变化来自想法变化，不是朗读。不要低沉御姐、性感气泡音、耳语、播音腔或嗲到幼儿化。',extra:'我只是把椅子调舒服了一点。又没说不写。你看，手已经放键盘上了。',emotion:'calm',speed:1.0}
];
async function api(endpoint,body){
 const res=await fetch('https://api.minimaxi.com/v1/'+endpoint,{method:'POST',redirect:'error',headers:{Authorization:'Bearer '+key,'Content-Type':'application/json'},body:JSON.stringify(body),signal:AbortSignal.timeout(55000)});
 if(!res.ok)throw Error('HTTP '+res.status);
 const data=await res.json();if(data.base_resp?.status_code!==0)throw Error('MiniMax '+data.base_resp?.status_code+': '+data.base_resp?.status_msg);
 return data;
}
async function save(){await fs.writeFile(mp,JSON.stringify(manifest,null,2));}
for(const v of variants){
 let design=manifest.designs.find(d=>d.id===v.id);
 if(!design){
  console.log('Design '+v.id);
  const r=await api('voice_design',{prompt:v.prompt,preview_text:text});
  if(!r.voice_id||!r.trial_audio)throw Error('Missing design audio');
  await fs.writeFile(path.join(dir,v.id+'.mp3'),Buffer.from(r.trial_audio,'hex'));
  design={id:v.id,title:v.title,prompt:v.prompt,voice_id:r.voice_id,round:2};
  manifest.designs.push(design);
  manifest.samples.unshift({id:v.id,title:v.title,voice_id:r.voice_id,language:'Chinese',text,direction:v.prompt,settings:{},kind:'design_preview',round:2,path:'res://assets/audio/voice_auditions/'+v.id+'.mp3'});
  await save();
 }
 const eid=v.id+'_acting';
 if(!manifest.samples.some(s=>s.id===eid)){
  console.log('Acting '+eid);
  const settings={voice_id:design.voice_id,speed:v.speed,vol:1,pitch:0,emotion:v.emotion};
  const r=await api('t2a_v2',{model:'speech-2.8-hd',text:v.extra,language_boost:'Chinese',stream:false,output_format:'hex',voice_setting:settings,audio_setting:{sample_rate:32000,bitrate:128000,format:'mp3',channel:1}});
  if(!r.data?.audio)throw Error('Missing synthesis audio');
  await fs.writeFile(path.join(dir,eid+'.mp3'),Buffer.from(r.data.audio,'hex'));
  manifest.samples.unshift({id:eid,title:v.title+' / 表演',voice_id:design.voice_id,language:'Chinese',text:v.extra,direction:v.prompt,settings,round:2,path:'res://assets/audio/voice_auditions/'+eid+'.mp3',...r.extra_info});await save();
 }
}
const order=['r2_a','r2_b','r2_c','r2_d','r2_a_acting','r2_b_acting','r2_c_acting','r2_d_acting'];
manifest.samples.sort((a,b)=>{const i=order.indexOf(a.id),j=order.indexOf(b.id);return (i<0?100:i)-(j<0?100:j);});
await save();console.log('DONE: four new voices, eight clips.');
