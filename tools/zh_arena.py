# zh_arena.py — 台词擂台：同一份 brief，喂给多个模型，产出并排对比稿。
#
# 省 token 的设计：brief（风格手册+场景+原稿+任务）只组装一次——
#   - MiniMax / DeepSeek 收到完全相同的 prompt 字符串；
#   - brief 同时落盘成 <slug>_brief.md，Codex（本地 agent）直接读文件，不重复传内容；
#   - Claude 的版本由 Claude 在会话里自己写，零 API 成本。
#
# 用法（项目根目录）：
#   python tools/zh_arena.py --slug ep0_opening --mode dialogue \
#       --scene "开场D：她刚被抓到打游戏" --file 台词文件.txt
#   （或 --text "台词内容"）
#
# 输出：tools/zh_arena_out/<slug>_brief.md（共享 brief）
#       tools/zh_arena_out/<slug>_minimax.md / <slug>_deepseek.md（各模型稿）
# 之后由 Claude 汇总成对比页。owner 8/20 起：每个选项直接标注模型，不盲测。
#
# 需要 MINIMAX_API_KEY 和 DEEPSEEK_API_KEY。

import argparse
import os
import re
import sys
from pathlib import Path

for stream in (sys.stdout, sys.stderr):
    try:
        stream.reconfigure(encoding="utf-8")
    except Exception:
        pass

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "tools" / "zh_arena_out"
OUT.mkdir(exist_ok=True)
sys.path.insert(0, str(ROOT / "tools" / "python_libs"))
from openai import OpenAI  # noqa: E402

THINK_RE = re.compile(r"<think>[\s\S]*?</think>\s*", re.IGNORECASE)

PROVIDERS = {
    # name: (env key, base_url, model)
    # minimax benched by owner decision 2026-08-17 (round-4 verdict) — writers are
    # now DeepSeek + Codex + Claude. MiniMax stays for in-game runtime + polish.
    "deepseek": ("DEEPSEEK_API_KEY", "https://api.deepseek.com", "deepseek-v4-pro"),
}

TASK_DIALOGUE = """任务：下面是游戏《Project Chill》里角色 Yua 的一场戏的草稿。请你**当编剧，不当翻译**——
把这场戏重新写一遍，目标是更可爱、更地道、更好笑，保持二次元少女感。
你可以自由改动：
- 每一拍的内容、笑点、比喻（只要更好笑更可爱）
- 但**拍子顺序以草稿里的标注为准**（标了「顺序已锁定」就不能重排——那是真人验收后立的规矩，
  因为顺序=现实中两个人对话的合理流程）
- 梗和比喻（必须长在情境里；不用网络流行语）
- 句式和节奏（怎么顺口怎么来）
必须守住的只有三样：
- 这场戏的功能（每拍旁边标注的剧情作用要达成）
- 她的人设和事实（风格手册「目标线」+「Yua 台词专用」两节是铁律）
- {name} 这类占位符原样保留
输出：重写后的台词，逐拍编号；如果你调整了叙事结构，用一行小字说明改了什么。"""

TASK_DOC = """任务：按风格手册把下面的文字改写得自然、地道、没有翻译腔。保留原意、事实、
专有名词和格式。只输出改写后的全文，不要解释。"""


def call_provider(name: str, prompt: str) -> str:
    env_key, base_url, model = PROVIDERS[name]
    key = os.environ.get(env_key, "")
    if not key:
        return f"[跳过 {name}：缺少 {env_key}]"
    client = OpenAI(api_key=key, base_url=base_url)
    # Editor-freedom prompts make reasoning models think MUCH longer; give the
    # think block plenty of room or it eats the whole budget (finish=length).
    r = client.chat.completions.create(
        model=model,
        messages=[{"role": "user", "content": prompt}],
        max_tokens=32000,
    )
    raw = r.choices[0].message.content or ""
    out = THINK_RE.sub("", raw).strip()
    if "<think>" in out:
        out = out.split("<think>")[0].strip()
    return out or f"[{name} 空响应 finish={r.choices[0].finish_reason}]"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--slug", required=True)
    ap.add_argument("--mode", choices=["dialogue", "doc"], default="dialogue")
    ap.add_argument("--scene", default="")
    ap.add_argument("--file")
    ap.add_argument("--text")
    ap.add_argument("--extra", help="逗号分隔的附加文件（背景包/口味档案等），一并写进 brief")
    args = ap.parse_args()

    source = args.text or Path(args.file).read_text(encoding="utf-8")
    style = (ROOT / "docs" / "Chinese_Style_Guide.md").read_text(encoding="utf-8")
    task = TASK_DIALOGUE if args.mode == "dialogue" else TASK_DOC

    extra_blocks = ""
    if args.extra:
        for p in args.extra.split(","):
            path = Path(p.strip())
            extra_blocks += f"\n\n=== {path.name} ===\n" + path.read_text(encoding="utf-8")

    brief = (f"{task}\n\n=== 场景 ===\n{args.scene or '（无额外场景说明）'}\n\n"
             f"=== 风格手册 ===\n{style}{extra_blocks}\n\n=== 台词草稿 ===\n{source}")
    brief_path = OUT / f"{args.slug}_brief.md"
    brief_path.write_text(brief, encoding="utf-8")
    print(f"brief -> {brief_path.relative_to(ROOT)} ({len(brief)} chars)")

    # Providers run in parallel — reasoning models can take minutes each.
    from concurrent.futures import ThreadPoolExecutor
    def run_one(name: str) -> None:
        print(f"calling {name} ...", flush=True)
        try:
            result = call_provider(name, brief)
        except Exception as e:
            result = f"[{name} 调用失败: {e}]"
        out_path = OUT / f"{args.slug}_{name}.md"
        out_path.write_text(result, encoding="utf-8")
        print(f"  -> {out_path.relative_to(ROOT)} ({len(result)} chars)", flush=True)

    with ThreadPoolExecutor(max_workers=len(PROVIDERS)) as pool:
        list(pool.map(run_one, PROVIDERS))


if __name__ == "__main__":
    main()
