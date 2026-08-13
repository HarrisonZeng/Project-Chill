# yua_studio.py — chat with Yua's exact game persona, with persistent memory.
#
# What this is for (owner workflow):
#   1. Talk to her casually to FEEL the voice. She remembers across sessions.
#   2. /remember to teach her facts by hand; /distill to auto-save what came up.
#   3. /draft <scene> to have her improvise script lines in-character (saved to drafts.md).
#   4. Edit data/dialogue/yua_system_prompt.txt / yua_world.txt to change WHO SHE IS —
#      this tool re-reads those files every time you run it, and the game uses the
#      same files, so persona edits apply to both at once.
#
# Run (from the project folder):
#   & "C:\Users\zengh\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe" -X utf8 tools\yua_studio.py
#
# Needs POE_API_KEY in the environment (same key the game uses).

import json
import os
import re
import sys
from datetime import datetime
from pathlib import Path

for stream in (sys.stdout, sys.stderr):
    try:
        stream.reconfigure(encoding="utf-8")
    except Exception:
        pass

ROOT = Path(__file__).resolve().parent.parent
STUDIO = ROOT / "tools" / "yua_studio_data"
STUDIO.mkdir(exist_ok=True)
MEMORY_FILE = STUDIO / "memory.md"
HISTORY_FILE = STUDIO / "history.jsonl"
DRAFTS_FILE = STUDIO / "drafts.md"
CONFIG_FILE = STUDIO / "config.json"

sys.path.insert(0, str(ROOT / "tools" / "python_libs"))
from openai import OpenAI  # noqa: E402

CONTEXT_TURNS = 40  # messages of rolling context sent to the model
THINK_RE = re.compile(r"<think>[\s\S]*?</think>\s*", re.IGNORECASE)


def pick_provider(cfg: dict):
    """Provider preference: config override > MiniMax subscription > Poe.
    Returns (api_key, base_url, default_model, label)."""
    if cfg.get("base_url") and cfg.get("key_env"):
        key = os.environ.get(cfg["key_env"], "")
        return key, cfg["base_url"], cfg.get("model", "MiniMax-M3"), cfg["key_env"]
    mm = os.environ.get("MINIMAX_API_KEY", "")
    if mm:
        return mm, "https://api.minimaxi.com/v1", "MiniMax-M3", "MiniMax 直连"
    poe = os.environ.get("POE_API_KEY", "")
    return poe, "https://api.poe.com/v1", "minimax-m2.7", "Poe"

HELP = """命令（其他输入都当成对她说话）：
  /mem            看她现在记住的所有事
  /remember 内容   手动写进她的长期记忆
  /distill        让模型把本次聊天里值得记的事提炼进长期记忆
  /draft 场景描述  排练模式：她以角色身份为这个场景即兴 5 版台词（存 drafts.md）
  /model 名字      换模型（如 claude-sonnet-4.5 / gpt-5.1 / deepseek-v3.2，Poe 上的名字都行）
  /model          看当前模型
  /help  /exit
"""


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def load_config() -> dict:
    try:
        return json.loads(read_text(CONFIG_FILE) or "{}")
    except json.JSONDecodeError:
        return {}


def save_config(cfg: dict) -> None:
    CONFIG_FILE.write_text(json.dumps(cfg, ensure_ascii=False, indent=2), encoding="utf-8")


# The GAME injects a per-call context packet with relationship stage + hard
# gates; without an equivalent the studio Yua drifts warmer than the game Yua.
# Override the default by setting "stage_note" in yua_studio_data/config.json.
DEFAULT_STAGE_NOTE = (
    "[context] 现在的关系阶段：认识不久的固定自习搭子——见过几次，聊得来，"
    "但还处在互相熟悉的阶段。写作的事你还没有向对方坦白过。"
    "绝不表现得比这个阶段更亲密、更外露；亲近感只能从行动里透出来，不能说出口。"
)


def build_system_prompt() -> str:
    persona = read_text(ROOT / "data/dialogue/yua_system_prompt.txt")
    world = read_text(ROOT / "data/dialogue/yua_world.txt")
    rules = read_text(ROOT / "data/dialogue/yua_runtime_rules.txt")
    memory = read_text(MEMORY_FILE).strip()
    stage_note = load_config().get("stage_note", DEFAULT_STAGE_NOTE)
    parts = [persona, world]
    if memory:
        parts.append(
            "[你们长期相处中，你真实记得的关于对方的事 — 用得少而准，绝不复述清单]\n" + memory
        )
    if stage_note:
        parts.append(stage_note)
    parts.append(rules)
    return "\n\n".join(p for p in parts if p.strip())


def append_history(role: str, content: str) -> None:
    with HISTORY_FILE.open("a", encoding="utf-8") as f:
        f.write(json.dumps({"t": datetime.now().isoformat(timespec="seconds"),
                            "role": role, "content": content}, ensure_ascii=False) + "\n")


def load_recent_history() -> list:
    msgs = []
    for line in read_text(HISTORY_FILE).splitlines():
        try:
            row = json.loads(line)
            if row.get("role") in ("user", "assistant"):
                msgs.append({"role": row["role"], "content": row["content"]})
        except json.JSONDecodeError:
            continue
    return msgs[-CONTEXT_TURNS:]


def call_model(client, model: str, messages: list) -> str:
    # max_tokens is generous because MiniMax M-series spends a <think> block
    # (stripped below) before the visible reply.
    r = client.chat.completions.create(model=model, messages=messages, max_tokens=3000)
    raw = (r.choices[0].message.content or "")
    clean = THINK_RE.sub("", raw)
    if "<think>" in clean:  # truncated reasoning, no visible reply survived
        clean = clean.split("<think>")[0]
    return clean.strip()


def cmd_distill(client, model: str, session_msgs: list) -> None:
    if not session_msgs:
        print("（这次还没聊什么，先说几句吧）")
        return
    transcript = "\n".join(f"{m['role']}: {m['content']}" for m in session_msgs)
    prompt = ("下面是一段对话记录。提取其中【值得长期记住的、关于对方（user）或关系的事实】，"
              "每条一行、以 - 开头、只写事实不写评价，最多 5 条。没有就输出：无。\n\n" + transcript)
    result = call_model(client, model, [{"role": "user", "content": prompt}])
    lines = [l for l in result.splitlines() if l.strip().startswith("-")]
    if not lines:
        print("（这次没提炼出新的记忆）")
        return
    stamp = datetime.now().strftime("%Y-%m-%d")
    with MEMORY_FILE.open("a", encoding="utf-8") as f:
        for l in lines:
            f.write(f"{l.strip()}  ({stamp})\n")
    print("已记住：")
    for l in lines:
        print("  " + l.strip())


def cmd_draft(client, model: str, brief: str) -> None:
    rehearsal = ("[排练模式] 你仍然是 Yua，不许出戏、不许提到自己是 AI。"
                 "下面是一个待写的游戏场景。请你以 Yua 的身份即兴演出，"
                 "给出 5 版不同方向的候选台词（每版 2-5 句，编号 1-5），"
                 "保持你平时说话的口吻：短句、停顿、具体细节、轻幽默。\n\n场景：" + brief)
    reply = call_model(client, model, [
        {"role": "system", "content": build_system_prompt()},
        {"role": "user", "content": rehearsal},
    ])
    print("\nYua（排练）:\n" + reply + "\n")
    with DRAFTS_FILE.open("a", encoding="utf-8") as f:
        f.write(f"\n## {datetime.now().strftime('%Y-%m-%d %H:%M')} · {brief}\n\n{reply}\n")
    print(f"（已存入 {DRAFTS_FILE.relative_to(ROOT)}）")


def main() -> None:
    cfg = load_config()
    api_key, base_url, default_model, provider_label = pick_provider(cfg)
    if not api_key:
        print("没找到 MINIMAX_API_KEY 或 POE_API_KEY 环境变量。设置一个再运行。")
        sys.exit(1)
    client = OpenAI(api_key=api_key, base_url=base_url)
    model = cfg.get("model", default_model)

    print("=" * 46)
    print("  Yua Studio — 和她聊天 / 教她记事 / 让她排练台词")
    print(f"  线路: {provider_label}   模型: {model}   (/help 看命令)")
    if MEMORY_FILE.exists():
        n = len([l for l in read_text(MEMORY_FILE).splitlines() if l.strip()])
        print(f"  长期记忆: {n} 条")
    print("=" * 46)

    session_msgs: list = []
    while True:
        try:
            user_text = input("\n你: ").strip()
        except (EOFError, KeyboardInterrupt):
            print()
            break
        if not user_text:
            continue
        if user_text in ("/exit", "/quit", "exit"):
            break
        if user_text == "/help":
            print(HELP)
            continue
        if user_text == "/mem":
            mem = read_text(MEMORY_FILE).strip()
            print(mem if mem else "（还没有长期记忆。用 /remember 或 /distill 添加）")
            continue
        if user_text.startswith("/remember"):
            fact = user_text[len("/remember"):].strip()
            if not fact:
                print("用法：/remember 他养了一只叫毛毛的猫")
                continue
            with MEMORY_FILE.open("a", encoding="utf-8") as f:
                f.write(f"- {fact}  ({datetime.now().strftime('%Y-%m-%d')})\n")
            print("已记住。")
            continue
        if user_text == "/distill":
            cmd_distill(client, model, session_msgs)
            continue
        if user_text.startswith("/draft"):
            brief = user_text[len("/draft"):].strip()
            if not brief:
                print("用法：/draft 第一次专注结束，她刚被计时器铃声吓到")
                continue
            cmd_draft(client, model, brief)
            continue
        if user_text.startswith("/model"):
            new_model = user_text[len("/model"):].strip()
            if new_model:
                model = new_model
                cfg["model"] = model
                save_config(cfg)
                print(f"已切换到 {model}")
            else:
                print(f"当前模型: {model}")
            continue

        messages = ([{"role": "system", "content": build_system_prompt()}]
                    + load_recent_history()
                    + [{"role": "user", "content": user_text}])
        try:
            reply = call_model(client, model, messages)
        except Exception as e:
            print(f"（调用失败：{e}）")
            continue
        print("\nYua: " + reply)
        append_history("user", user_text)
        append_history("assistant", reply)
        session_msgs += [{"role": "user", "content": user_text},
                         {"role": "assistant", "content": reply}]

    print("下次见。（记忆和聊天记录都存在 tools/yua_studio_data/ 里）")


if __name__ == "__main__":
    main()
