#!/usr/bin/env python3
# build.py — assemble the script-review page from the live dialogue data.
#
# Reads data/dialogue/scripted_nodes.json + reactive_lines.json, walks every
# episode in PLAY ORDER (branch by branch, each node placed once), attaches the
# latest mechanical lint findings, and injects it all into template.html →
# review.html. Publish review.html as an Artifact with the `db` capability so
# verdicts/comments/edits persist; pull them back with apply.py.
#
#   python tools/script_review/build.py            # → tools/script_review/review.html
#   python tools/script_review/build.py --lint tools/script_review/lint_latest.txt
#
# Regenerate after every script change; the page shows the script version and
# build time so a stale page is obvious.

import argparse
import json
import re
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NODES_PATH = ROOT / "data" / "dialogue" / "scripted_nodes.json"
REACTIVE_PATH = ROOT / "data" / "dialogue" / "reactive_lines.json"
HERE = Path(__file__).resolve().parent
TEMPLATE = HERE / "template.html"
OUT = HERE / "review.html"

# Choice targets that are engine actions, not nodes.
SPECIAL_PREFIXES = ("AI_MODE_", "ACTION_", "EXIT_DONE_")

EP_TITLES = {
    "ep00": "Ep0 · 开场（开局翻车 → 取名 → 一起摸索）",
}

FUNCTIONAL_GROUPS = [
    ("focus", "专注 · 任务输入 / 开始 / 结束 / 中断",
     lambda i: i.startswith(("TASK_INPUT", "FOCUS_", "ABORT"))),
    ("return", "回流 · 再次上线时的开场",
     lambda i: i.startswith("return_open")),
    ("greeting", "时段问候 · 早 / 午 / 晚 / 夜",
     lambda i: i.startswith("greeting_")),
    ("exit", "离开 · 结束通话",
     lambda i: i.startswith("EXIT_") or i.startswith("quiet_end")),
    ("idle", "闲置", lambda i: i == "idle"),
]

LINT_RULE_ZH = {
    "ellipsis:opens-beat": "一拍以「……」开头",
    "ellipsis:>1/beat": "一拍两个「……」",
    "dash:>1/beat": "一拍多个「——」",
    "bang:>1/beat": "一拍多个「！」",
    "question:>1/beat": "一拍两个问句（问完给台阶）",
    "moe:>1/beat": "嘿嘿/呀/啦 叠用",
    "sentence:long": "句子超过 30 字，读着喘",
    "beat:long": "一拍超过 60 字",
    "de:3+/sentence": "一句三个「的」",
    "paren:stage-direction": "括号动作（persona 禁）",
    "token:name-punct": "{name} 后接标点，没取名会悬着",
    "token:unknown": "未知占位符",
    "english": "英文混入",
    "choice:long": "选项太长",
    "choice:session-mgmt": "选项像任务管理",
    "choice:blank": "空选项",
    "blank": "空台词",
}


def load_json(path: Path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def gate_label(ep: dict) -> str:
    parts = []
    gate = ep.get("session_gate")
    if gate:
        parts.append(f"第 {gate} 次专注结束后")
    unlock = ep.get("unlock") or {}
    secs = unlock.get("total_focus_seconds_min")
    if secs:
        parts.append(f"累计专注 ≥ {int(secs) // 60} 分钟")
    return " · ".join(parts)


def parse_lint(path: Path) -> dict:
    """lines look like: 'rule<spaces>node_id<spaces>detail' (script_lint output)."""
    out: dict = {}
    if not path or not path.exists():
        return out
    for raw in path.read_text(encoding="utf-8").splitlines():
        raw = raw.strip()
        if not raw:
            continue
        m = re.match(r"^(\S+)\s+(\S+)\s+(.*)$", raw)
        if not m:
            continue
        rule, node_id, detail = m.groups()
        # pool ids look like focus_click[3]
        out.setdefault(node_id, []).append({
            "rule": rule,
            "label": LINT_RULE_ZH.get(rule.split(":")[0] + ":" + rule.split(":", 1)[1] if ":" in rule else rule, rule),
            "detail": detail,
        })
    return out


def walk(start: str, nodes: dict, placed: set) -> list:
    """Depth-first in choice order; each node once; returns [{id, depth, via}]."""
    order = []

    def visit(node_id: str, depth: int, via: str):
        if node_id in placed or node_id not in nodes:
            return
        placed.add(node_id)
        order.append({"id": node_id, "depth": depth, "via": via})
        for c in nodes[node_id].get("choices", []):
            nxt = str(c.get("next", ""))
            if not nxt or nxt.startswith(SPECIAL_PREFIXES):
                continue
            if nxt in nodes and nxt not in placed:
                visit(nxt, depth + 1, str(c.get("text", "")))
            # already placed / special: rendered as an arrow on the chip
        # Typed-answer routing (Ep3 platform question etc.): keyword branches,
        # then where an unmatched / AI-covered answer continues to.
        routes = nodes[node_id].get("typed_routes") or {}
        for rule in routes.get("keywords", []) or []:
            nxt = str(rule.get("next", ""))
            words = "/".join(str(w) for w in (rule.get("match") or [])[:2])
            if nxt in nodes and nxt not in placed:
                visit(nxt, depth + 1, f"打字：{words}")
        for key, label in (("fallback_next", "打字：其他回答"), ("after_ai_next", "自由聊之后")):
            nxt = str(routes.get(key, ""))
            if nxt in nodes and nxt not in placed:
                visit(nxt, depth + 1, label)

    visit(start, 0, "")
    return order


def build(lint_path: Path | None) -> dict:
    root = load_json(NODES_PATH)
    reactive = load_json(REACTIVE_PATH)
    nodes = {}
    for n in root.get("nodes", []):
        nid = str(n.get("id", ""))
        if not nid:
            continue
        nodes[nid] = {
            "line": n.get("line", ""),
            "choices": [{"text": c.get("text", ""), "next": c.get("next", "")}
                        for c in n.get("choices", [])],
            "tags": n.get("tags", []),
            "set_flags": n.get("set_flags", []),
            "unlock": n.get("unlock", {}),
            "typed_routes": n.get("typed_routes", {}),
        }

    placed: set = set()
    groups = []

    # Ep0 (intro)
    intro = root.get("intro_node", "ep00_01")
    groups.append({
        "id": "ep00", "title": EP_TITLES["ep00"], "gate": "第一次打开",
        "nodes": walk(intro, nodes, placed),
    })
    # Ep1..N from metadata (play order = gate order)
    eps = sorted(root.get("episodes", []), key=lambda e: (e.get("session_gate", 0), e.get("id", "")))
    for ep in eps:
        start = ep.get("start_node", "")
        label = ep.get("label", ep.get("id", ""))
        groups.append({
            "id": ep.get("id", ""), "title": label, "gate": gate_label(ep),
            "nodes": walk(start, nodes, placed),
        })
    # Functional groups
    for gid, title, pred in FUNCTIONAL_GROUPS:
        members = [i for i in nodes if pred(i) and i not in placed]
        # keep each functional node's own sub-branches under it
        order = []
        for i in sorted(members):
            order += walk(i, nodes, placed)
        if order:
            groups.append({"id": gid, "title": title, "gate": "", "nodes": order})
    # Anything unreached
    rest = [i for i in nodes if i not in placed]
    if rest:
        order = []
        for i in sorted(rest):
            order += walk(i, nodes, placed)
        groups.append({"id": "other", "title": "其他 · 没有从主线到达的节点", "gate": "", "nodes": order})

    # Inbound map so a node can say "从哪儿来"
    inbound: dict = {}
    for nid, n in nodes.items():
        for c in n["choices"]:
            nxt = str(c["next"])
            if nxt in nodes:
                inbound.setdefault(nxt, []).append({"from": nid, "text": c["text"]})

    pools = {k: v for k, v in reactive.items() if not k.startswith("_") and isinstance(v, list)}

    return {
        "generated": datetime.now().strftime("%Y-%m-%d %H:%M"),
        "version": root.get("demo_script_version", ""),
        "groups": groups,
        "nodes": nodes,
        "inbound": inbound,
        "pools": pools,
        "lint": parse_lint(lint_path) if lint_path else {},
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--lint", default=str(HERE / "lint_latest.txt"))
    ap.add_argument("--out", default=str(OUT))
    args = ap.parse_args()

    data = build(Path(args.lint) if args.lint else None)
    template = TEMPLATE.read_text(encoding="utf-8")
    payload = json.dumps(data, ensure_ascii=False, separators=(",", ":"))
    # Guard against the one sequence that could close the script tag early.
    payload = payload.replace("</", "<\\/")
    html = template.replace("/*__DATA__*/null", payload)
    Path(args.out).write_text(html, encoding="utf-8")
    total = sum(len(g["nodes"]) for g in data["groups"])
    pools = sum(len(v) for v in data["pools"].values())
    print(f"review.html: {total} nodes in {len(data['groups'])} groups, {pools} pool lines, "
          f"{sum(len(v) for v in data['lint'].values())} lint notes → {args.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
