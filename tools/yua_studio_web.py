# yua_studio_web.py — Yua Studio for your PHONE.
#
# Runs a small web server on this PC; your phone opens it in a browser and you
# chat with the same Yua as the game and the CLI studio: same persona files,
# same long-term memory (tools/yua_studio_data/memory.md), same MiniMax model.
#
# Run: double-click tools\start_yua_phone.bat   (or:)
#   & "C:\Users\zengh\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" -X utf8 tools\yua_studio_web.py
#
# Phone URL (Tailscale, works anywhere):  http://100.67.144.104:8737/<token>/
#
# Features: multiple chat sessions (默认 session is shared with the CLI studio),
# rehearsal-mode toggle, long-term memory tools, and a persona editor (edits go
# live for BOTH studio and game on the next message; a timestamped backup is
# saved to tools/yua_studio_data/prompt_backups/ before every save).

import json
import secrets
import socket
import sys
from datetime import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import yua_studio as ys  # shares persona loading, memory files, model calls

from openai import OpenAI  # noqa: E402  (path set up by yua_studio import)

PORT = 8737

cfg = ys.load_config()
API_KEY, BASE_URL, DEFAULT_MODEL, PROVIDER_LABEL = ys.pick_provider(cfg)
if not API_KEY:
    print("没找到 MINIMAX_API_KEY 或 POE_API_KEY，先设置再运行。")
    sys.exit(1)
MODEL = cfg.get("model", DEFAULT_MODEL)
client = OpenAI(api_key=API_KEY, base_url=BASE_URL)

TOKEN = cfg.get("web_token") or secrets.token_hex(3)
if cfg.get("web_token") != TOKEN:
    cfg["web_token"] = TOKEN
    ys.save_config(cfg)

# ---------------------------------------------------------------- sessions ---
SESSIONS_DIR = ys.STUDIO / "sessions"
SESSIONS_DIR.mkdir(exist_ok=True)
SESSIONS_INDEX = ys.STUDIO / "sessions.json"
BACKUP_DIR = ys.STUDIO / "prompt_backups"
BACKUP_DIR.mkdir(exist_ok=True)

# Editable persona files. "rules" is engineering-flavored — shown last with a
# warning in the UI.
PROMPT_FILES = {
    "persona": ys.ROOT / "data/dialogue/yua_system_prompt.txt",
    "world": ys.ROOT / "data/dialogue/yua_world.txt",
    "rules": ys.ROOT / "data/dialogue/yua_runtime_rules.txt",
}

session_msgs: dict = {}  # session id -> messages of THIS server run (for distill)


def load_sessions() -> list:
    try:
        data = json.loads(ys.read_text(SESSIONS_INDEX) or "[]")
        if isinstance(data, list) and data:
            return data
    except json.JSONDecodeError:
        pass
    return [{"id": "default", "name": "默认（和电脑共用）"}]


def save_sessions(sessions: list) -> None:
    SESSIONS_INDEX.write_text(json.dumps(sessions, ensure_ascii=False, indent=2),
                              encoding="utf-8")


def session_file(session_id: str) -> Path:
    if session_id == "default":
        return ys.HISTORY_FILE  # the CLI studio's thread — kept shared on purpose
    safe = "".join(c for c in session_id if c.isalnum() or c in "-_")[:40]
    return SESSIONS_DIR / f"{safe}.jsonl"


def load_history(session_id: str, limit: int) -> list:
    msgs = []
    for line in ys.read_text(session_file(session_id)).splitlines():
        try:
            row = json.loads(line)
            if row.get("role") in ("user", "assistant"):
                msgs.append({"role": row["role"], "content": row["content"]})
        except json.JSONDecodeError:
            continue
    return msgs[-limit:]


def append_msg(session_id: str, role: str, content: str) -> None:
    with session_file(session_id).open("a", encoding="utf-8") as f:
        f.write(json.dumps({"t": datetime.now().isoformat(timespec="seconds"),
                            "role": role, "content": content}, ensure_ascii=False) + "\n")


# ------------------------------------------------------------------- model ---
def chat_reply(session_id: str, text: str) -> str:
    messages = ([{"role": "system", "content": ys.build_system_prompt()}]
                + load_history(session_id, ys.CONTEXT_TURNS)
                + [{"role": "user", "content": text}])
    reply = ys.call_model(client, MODEL, messages)
    append_msg(session_id, "user", text)
    append_msg(session_id, "assistant", reply)
    session_msgs.setdefault(session_id, []).extend(
        [{"role": "user", "content": text}, {"role": "assistant", "content": reply}])
    return reply


def draft_reply(session_name: str, brief: str) -> str:
    rehearsal = ("[排练模式] 你仍然是 Yua，不许出戏、不许提到自己是 AI。"
                 "下面是一个待写的游戏场景。请你以 Yua 的身份即兴演出，"
                 "给出 5 版不同方向的候选台词（每版 2-5 句，编号 1-5），"
                 "保持你平时说话的口吻：短句、停顿、具体细节、轻幽默。\n\n场景：" + brief)
    reply = ys.call_model(client, MODEL, [
        {"role": "system", "content": ys.build_system_prompt()},
        {"role": "user", "content": rehearsal}])
    with ys.DRAFTS_FILE.open("a", encoding="utf-8") as f:
        f.write(f"\n## {datetime.now().strftime('%Y-%m-%d %H:%M')} · [手机·{session_name}] {brief}\n\n{reply}\n")
    return reply


def distill_now(session_id: str) -> list:
    msgs = session_msgs.get(session_id, [])
    if not msgs:
        return []
    transcript = "\n".join(f"{m['role']}: {m['content']}" for m in msgs)
    prompt = ("下面是一段对话记录。提取其中【值得长期记住的、关于对方（user）或关系的事实】，"
              "每条一行、以 - 开头、只写事实不写评价，最多 5 条。没有就输出：无。\n\n" + transcript)
    result = ys.call_model(client, MODEL, [{"role": "user", "content": prompt}])
    lines = [l.strip() for l in result.splitlines() if l.strip().startswith("-")]
    if lines:
        stamp = datetime.now().strftime("%Y-%m-%d")
        with ys.MEMORY_FILE.open("a", encoding="utf-8") as f:
            for l in lines:
                f.write(f"{l}  ({stamp})\n")
        session_msgs[session_id] = []
    return lines


def save_prompt(file_key: str, content: str) -> str:
    path = PROMPT_FILES.get(file_key)
    if path is None:
        return "unknown file"
    if len(content.strip()) < 40:
        return "内容太短，怕是误删——没有保存。"
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = BACKUP_DIR / f"{path.stem}-{stamp}.txt"
    backup.write_text(ys.read_text(path), encoding="utf-8")
    path.write_text(content, encoding="utf-8")
    return ""


# -------------------------------------------------------------------- page ---
PAGE = """<!DOCTYPE html><html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<title>Yua Studio</title><style>
:root{--bg:#171310;--card:#2b2119;--cream:#f3e9d8;--amber:#e8b96f;--dim:#9c8b72}
*{box-sizing:border-box}body{margin:0;background:var(--bg);color:var(--cream);
font-family:-apple-system,"PingFang SC","Microsoft YaHei",sans-serif;display:flex;
flex-direction:column;height:100dvh}
header{padding:8px 12px;display:flex;gap:8px;align-items:center;border-bottom:1px solid #3a2d1f}
header b{color:var(--amber);font-size:15px;white-space:nowrap}
#sess{flex:1;background:var(--card);color:var(--cream);border:1px solid #4a3a28;
border-radius:10px;padding:6px 8px;font-size:14px;min-width:0}
#newSess{background:var(--card);color:var(--amber);border:1px solid #4a3a28;border-radius:10px;
padding:6px 12px;font-size:15px;font-weight:700}
#log{flex:1;overflow-y:auto;padding:12px;display:flex;flex-direction:column;gap:10px}
.msg{max-width:86%;padding:10px 13px;border-radius:14px;line-height:1.55;font-size:15px;
white-space:pre-wrap;word-break:break-word}
.yua{background:var(--card);border:1px solid #4a3a28;border-top-left-radius:4px;align-self:flex-start}
.me{background:#3d2f22;border-top-right-radius:4px;align-self:flex-end}
.sys{align-self:center;color:var(--dim);font-size:12.5px;max-width:92%;white-space:pre-wrap}
#bar{display:flex;gap:8px;padding:10px;border-top:1px solid #3a2d1f}
#inp{flex:1;background:var(--card);border:1px solid #4a3a28;border-radius:20px;color:var(--cream);
padding:10px 14px;font-size:15px;outline:none}
#send{background:var(--amber);color:#2a2018;border:0;border-radius:20px;padding:0 18px;
font-size:15px;font-weight:600}
#tools{display:flex;gap:8px;padding:0 10px 10px;flex-wrap:wrap}
#tools button{background:var(--card);color:var(--cream);border:1px solid #4a3a28;
border-radius:16px;padding:6px 12px;font-size:13px}
#tools button.on{background:var(--amber);color:#2a2018;border-color:var(--amber);font-weight:600}
#editor{position:fixed;inset:0;background:var(--bg);display:none;flex-direction:column;z-index:9}
#editor.open{display:flex}
#etabs{display:flex;gap:6px;padding:10px 12px 0}
#etabs button{background:var(--card);color:var(--cream);border:1px solid #4a3a28;
border-radius:10px 10px 0 0;padding:8px 14px;font-size:14px}
#etabs button.on{background:var(--amber);color:#2a2018;font-weight:600}
#ewarn{color:var(--dim);font-size:12px;padding:6px 14px}
#etext{flex:1;margin:0 12px;background:var(--card);color:var(--cream);border:1px solid #4a3a28;
border-radius:0 10px 10px 10px;padding:12px;font-size:14px;line-height:1.6;resize:none;outline:none}
#ebar{display:flex;gap:8px;padding:12px}
#ebar button{flex:1;border:0;border-radius:14px;padding:12px;font-size:15px;font-weight:600}
#esave{background:var(--amber);color:#2a2018}#eclose{background:var(--card);color:var(--cream);
border:1px solid #4a3a28 !important}
</style></head><body>
<header><b>Yua</b><select id="sess"></select><button id="newSess" onclick="newSession()">＋</button></header>
<div id="log"></div>
<div id="tools">
  <button onclick="mem()">她记得什么</button>
  <button onclick="distill()">提炼记忆</button>
  <button id="draftBtn" onclick="toggleDraft()">排练台词</button>
  <button onclick="openEditor()">编辑人设</button>
</div>
<div id="bar"><input id="inp" placeholder="说点什么…" autocomplete="off">
<button id="send" onclick="send()">发送</button></div>

<div id="editor">
  <div id="etabs">
    <button data-f="persona" class="on" onclick="etab(this)">人设</button>
    <button data-f="world" onclick="etab(this)">世界</button>
    <button data-f="rules" onclick="etab(this)">规则⚠</button>
  </div>
  <div id="ewarn">改动会立刻影响手机版、电脑版和游戏本体（下一条消息生效）。保存前会自动备份。「规则⚠」偏工程向，谨慎改。</div>
  <textarea id="etext" spellcheck="false"></textarea>
  <div id="ebar"><button id="esave" onclick="esave()">保存</button>
  <button id="eclose" onclick="ecl()">关闭</button></div>
</div>

<script>
const log=document.getElementById('log'),inp=document.getElementById('inp'),
sessSel=document.getElementById('sess'),draftBtn=document.getElementById('draftBtn');
let drafting=false,active=localStorage.getItem('yua_session')||'default',efile='persona',edirty=false;
function add(cls,text){const d=document.createElement('div');d.className='msg '+cls;
d.textContent=text;log.appendChild(d);log.scrollTop=log.scrollHeight;return d}
async function api(path,body){const r=await fetch('api/'+path,{method:'POST',
headers:{'Content-Type':'application/json'},body:JSON.stringify(body||{})});
return await r.json()}
async function loadSessions(){const r=await api('sessions/list');sessSel.innerHTML='';
let found=false;
for(const s of r.sessions){const o=document.createElement('option');o.value=s.id;
o.textContent=s.name;if(s.id===active){o.selected=true;found=true}sessSel.appendChild(o)}
if(!found){active='default';sessSel.value='default'}}
async function loadHistory(){log.innerHTML='';
const r=await api('sessions/history',{session:active});
if(!r.messages||!r.messages.length){add('sys','（新的开始。她在。）');return}
for(const m of r.messages)add(m.role==='user'?'me':'yua',m.content);
add('sys','—— 以上是之前聊的 ——')}
sessSel.addEventListener('change',async()=>{active=sessSel.value;
localStorage.setItem('yua_session',active);await loadHistory()});
async function newSession(){const name=prompt('给这个会话起个名（比如：测试撒娇边界）');
if(!name)return;const r=await api('sessions/new',{name:name});
if(r.id){active=r.id;localStorage.setItem('yua_session',active);
await loadSessions();sessSel.value=active;await loadHistory()}}
async function send(){const t=inp.value.trim();if(!t)return;inp.value='';
add('me',t);const wait=add('sys',drafting?'排练中……':'她在打字……');
try{const r=await api(drafting?'draft':'chat',{text:t,session:active});
wait.remove();add(drafting?'sys':'yua',r.reply||('出错了: '+(r.error||'?')));}
catch(e){wait.textContent='网络错误，重试一下'}}
function toggleDraft(){drafting=!drafting;draftBtn.classList.toggle('on',drafting);
inp.placeholder=drafting?'描述场景，她来即兴台词…（再点一次按钮退出）':'说点什么…';
if(drafting)add('sys','排练模式已开：接下来发的消息都当作场景描述。再点一次「排练台词」退出。');
else add('sys','排练模式已关。')}
async function mem(){const r=await api('memory');add('sys',r.memory||'（还没有长期记忆）')}
async function distill(){const w=add('sys','提炼中……');const r=await api('distill',{session:active});
w.textContent=r.added&&r.added.length?('已记住：\\n'+r.added.join('\\n')):'（这次没提炼出新的记忆）'}
async function openEditor(){document.getElementById('editor').classList.add('open');
await eload()}
async function eload(){const r=await api('prompt/get',{file:efile});
document.getElementById('etext').value=r.content||'';edirty=false}
async function etab(btn){if(edirty&&!confirm('当前页有未保存的改动，切换会丢失。继续？'))return;
document.querySelectorAll('#etabs button').forEach(b=>b.classList.remove('on'));
btn.classList.add('on');efile=btn.dataset.f;await eload()}
document.getElementById('etext').addEventListener('input',()=>{edirty=true});
async function esave(){const r=await api('prompt/save',
{file:efile,content:document.getElementById('etext').value});
if(r.error){alert(r.error)}else{edirty=false;alert('已保存（旧版已自动备份）')}}
function ecl(){if(edirty&&!confirm('有未保存的改动，确定关闭？'))return;
document.getElementById('editor').classList.remove('open')}
inp.addEventListener('keydown',e=>{if(e.key==='Enter'){e.preventDefault();send()}});
(async()=>{await loadSessions();await loadHistory()})();
</script></body></html>"""

# ----------------------------------------------------------------- server ---
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer  # noqa: E402


class Handler(BaseHTTPRequestHandler):
    def _send(self, code: int, body: bytes, ctype: str) -> None:
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _json(self, obj: dict, code: int = 200) -> None:
        self._send(code, json.dumps(obj, ensure_ascii=False).encode("utf-8"),
                   "application/json; charset=utf-8")

    def log_message(self, *args) -> None:
        pass

    def do_GET(self) -> None:
        if self.path.rstrip("/") == f"/{TOKEN}":
            self._send(200, PAGE.encode("utf-8"), "text/html; charset=utf-8")
        else:
            self._send(404, b"not found", "text/plain")

    def do_POST(self) -> None:
        if not self.path.startswith(f"/{TOKEN}/api/"):
            self._send(404, b"not found", "text/plain")
            return
        action = self.path[len(f"/{TOKEN}/api/"):]
        try:
            length = int(self.headers.get("Content-Length", 0))
            data = json.loads(self.rfile.read(length) or b"{}")
        except (ValueError, json.JSONDecodeError):
            data = {}
        text = str(data.get("text", "")).strip()
        session_id = str(data.get("session", "default")).strip() or "default"
        try:
            if action == "chat" and text:
                self._json({"reply": chat_reply(session_id, text)})
            elif action == "draft" and text:
                name = next((s["name"] for s in load_sessions() if s["id"] == session_id), session_id)
                self._json({"reply": draft_reply(name, text)})
            elif action == "memory":
                self._json({"memory": ys.read_text(ys.MEMORY_FILE).strip()})
            elif action == "distill":
                self._json({"added": distill_now(session_id)})
            elif action == "sessions/list":
                self._json({"sessions": load_sessions()})
            elif action == "sessions/new":
                name = str(data.get("name", "")).strip() or "未命名"
                sessions = load_sessions()
                new_id = "s" + secrets.token_hex(3)
                sessions.append({"id": new_id, "name": name})
                save_sessions(sessions)
                self._json({"id": new_id})
            elif action == "sessions/history":
                self._json({"messages": load_history(session_id, 30)})
            elif action == "prompt/get":
                path = PROMPT_FILES.get(str(data.get("file", "")))
                if path is None:
                    self._json({"error": "unknown file"}, 400)
                else:
                    self._json({"content": ys.read_text(path)})
            elif action == "prompt/save":
                err = save_prompt(str(data.get("file", "")), str(data.get("content", "")))
                self._json({"error": err} if err else {"ok": True})
            else:
                self._json({"error": "bad request"}, 400)
        except Exception as e:
            self._json({"error": str(e)[:200]}, 500)


def lan_ip() -> str:
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except OSError:
        return "127.0.0.1"


if __name__ == "__main__":
    # Windows allows two servers to bind the same port when reuse is on, and the
    # STALE one keeps answering — refuse to start instead.
    ThreadingHTTPServer.allow_reuse_address = False
    try:
        server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
    except OSError:
        print("端口 8737 已被占用 —— 大概已经有一个 Yua Studio 在运行。")
        print("先关掉那个窗口再启动；找不到窗口就重启电脑，或让 Claude 清理。")
        sys.exit(1)
    print("=" * 56)
    print("  Yua Studio (手机版) 已启动")
    print(f"  同一 Wi-Fi:  http://{lan_ip()}:{PORT}/{TOKEN}/")
    print(f"  任何地方(Tailscale):  http://100.67.144.104:{PORT}/{TOKEN}/")
    print("  停止: 这个窗口按 Ctrl+C")
    print("=" * 56)
    server.serve_forever()
