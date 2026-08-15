# zh_polish.py — 中文润色流水线：用 native 中文模型按《中文风格手册》改稿。
#
# 用法（项目根目录）：
#   润色一段文字:   python tools/zh_polish.py --text "要润色的内容"
#   润色整个文件:   python tools/zh_polish.py docs/某文档.md
#   台词模式:       python tools/zh_polish.py --mode dialogue --text "Yua的台词"
#   换模型:         python tools/zh_polish.py --model MiniMax-M2.7 ...
#
# 输出：润色稿 + 逐条改动理由。不直接覆盖原文件——人看过再采纳。
# 需要 MINIMAX_API_KEY（游戏同款）。

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
sys.path.insert(0, str(ROOT / "tools" / "python_libs"))
from openai import OpenAI  # noqa: E402

STYLE_GUIDE = (ROOT / "docs" / "Chinese_Style_Guide.md").read_text(encoding="utf-8")
THINK_RE = re.compile(r"<think>[\s\S]*?</think>\s*", re.IGNORECASE)

PROMPT_DOC = """你是一位以中文为母语的资深文案编辑。下面有一份《风格手册》和一段待润色的文字。
任务：按手册把文字改得自然、口语顺滑、没有翻译腔，同时**严格保留原意、事实、专有名词和格式结构**
（Markdown 标记、HTML 标签、{name} 这类占位符一律原样保留）。

输出格式：
【润色稿】
（改后的全文）
【改动清单】
- 原句 → 改后 ｜ 理由（对应手册哪条）
（只列有实质改动的，最多 15 条）"""

PROMPT_DIALOGUE = """你是一位以中文为母语的游戏编剧，擅长写年轻女性角色的日常口语台词。
下面有一份《风格手册》（重点看「Yua 台词专用」一节）和几句待润色的台词。
任务：让每句话像一个 21 岁、安静但明亮的女孩子当下随口说出来的话。守住手册的硬规矩。
保留 {name}、{focus_minutes} 等占位符和分行结构。

输出格式：
【润色稿】
（改后台词，保持原分行）
【改动清单】
- 原句 → 改后 ｜ 理由"""


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("file", nargs="?", help="要润色的文件路径")
    ap.add_argument("--text", help="直接润色这段文字")
    ap.add_argument("--mode", choices=["doc", "dialogue"], default="doc")
    ap.add_argument("--model", default="MiniMax-M3")
    args = ap.parse_args()

    if args.text:
        source = args.text
    elif args.file:
        source = Path(args.file).read_text(encoding="utf-8")
    else:
        print("给我文件路径，或用 --text 直接给文字。")
        sys.exit(1)

    key = os.environ.get("MINIMAX_API_KEY", "")
    if not key:
        print("没找到 MINIMAX_API_KEY。")
        sys.exit(1)
    client = OpenAI(api_key=key, base_url="https://api.minimaxi.com/v1")

    task = PROMPT_DIALOGUE if args.mode == "dialogue" else PROMPT_DOC
    user = f"{task}\n\n=== 风格手册 ===\n{STYLE_GUIDE}\n\n=== 待润色文字 ===\n{source}"
    # M-series models think at length before answering; a tight budget can end
    # inside the <think> block and strip to nothing.
    r = client.chat.completions.create(
        model=args.model,
        messages=[{"role": "user", "content": user}],
        max_tokens=16000,
    )
    raw = r.choices[0].message.content or ""
    out = THINK_RE.sub("", raw).strip()
    if "<think>" in out:
        out = out.split("<think>")[0].strip()
    if not out:
        print("（模型这次全在思考没给出正文，再跑一次通常就好；finish_reason=%s）"
              % r.choices[0].finish_reason)
        sys.exit(2)
    print(out)


if __name__ == "__main__":
    main()
