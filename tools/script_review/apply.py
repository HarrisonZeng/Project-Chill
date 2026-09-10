#!/usr/bin/env python3
# apply.py — bring the owner's review back into the script.
#
# Input: a directory of review documents pulled from the artifact database
# (Claude: `Artifact read_db --collection review --out_dir <dir>`), one JSON per
# node, shaped like the page writes them:
#   { "verdict": "keep"|"edit"|"cut"|"", "comment": "...",
#     "line": "<edited line or null>", "choices": {"0": "new chip text", ...},
#     "updated_at": "..." }
#
# What it does:
#   * verdict "edit" with a changed line/choice text → written into
#     data/dialogue/scripted_nodes.json (a timestamped backup is saved first)
#   * pool lines (ids like focus_click[3]) → written into reactive_lines.json
#   * every comment and every "cut" → printed as a checklist for the script
#     session (cuts are NOT applied automatically: removing a node changes the
#     graph and needs a human)
#
#   python tools/script_review/apply.py <review_dir> [--dry-run]

import argparse
import json
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
NODES_PATH = ROOT / "data" / "dialogue" / "scripted_nodes.json"
REACTIVE_PATH = ROOT / "data" / "dialogue" / "reactive_lines.json"
# Pool line ids: the page writes `focus_click~3` (db paths allow no brackets);
# the older lint format `focus_click[3]` is accepted too.
POOL_ID = re.compile(r"^([a-z_]+)(?:~|\[)(\d+)\]?$")


def load(path: Path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def save(path: Path, data, dry: bool) -> None:
    if dry:
        return
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup = path.with_name(f"{path.stem}.backup-{stamp}{path.suffix}")
    shutil.copy2(path, backup)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"  wrote {path.name}  (backup: {backup.name})")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("review_dir")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    review_dir = Path(args.review_dir)
    docs = {}
    for p in sorted(review_dir.rglob("*.json")):
        try:
            docs[p.stem] = load(p)
        except Exception as e:  # noqa: BLE001
            print(f"skip {p.name}: {e}")
    if not docs:
        print("no review documents found")
        return 1

    root = load(NODES_PATH)
    reactive = load(REACTIVE_PATH)
    by_id = {str(n.get("id")): n for n in root.get("nodes", [])}

    applied, comments, cuts = [], [], []
    nodes_dirty = pools_dirty = False

    for doc_id, d in docs.items():
        verdict = str(d.get("verdict", "") or "")
        comment = str(d.get("comment", "") or "").strip()
        if comment:
            comments.append((doc_id, verdict, comment))
        if verdict == "cut":
            cuts.append(doc_id)
        if verdict != "edit":
            continue

        m = POOL_ID.match(doc_id)
        if m:
            cat, idx = m.group(1), int(m.group(2))
            new_line = d.get("line")
            pool = reactive.get(cat)
            if isinstance(pool, list) and idx < len(pool) and isinstance(new_line, str) \
                    and new_line.strip() and new_line != pool[idx]:
                applied.append((doc_id, pool[idx], new_line))
                pool[idx] = new_line
                pools_dirty = True
            continue

        node = by_id.get(doc_id)
        if node is None:
            print(f"  ! {doc_id}: node no longer exists, comment kept only")
            continue
        new_line = d.get("line")
        if isinstance(new_line, str) and new_line.strip() and new_line != node.get("line", ""):
            applied.append((doc_id, node.get("line", ""), new_line))
            node["line"] = new_line
            nodes_dirty = True
        for k, text in (d.get("choices") or {}).items():
            try:
                i = int(k)
            except ValueError:
                continue
            choices = node.get("choices", [])
            if i < len(choices) and isinstance(text, str) and text.strip() and text != choices[i].get("text"):
                applied.append((f"{doc_id} · 选项{i + 1}", choices[i].get("text", ""), text))
                choices[i]["text"] = text
                nodes_dirty = True

    print(f"review docs: {len(docs)}  ·  edits: {len(applied)}  ·  comments: {len(comments)}  ·  cuts: {len(cuts)}")
    if applied:
        print("\n== EDITS" + (" (dry run, not written)" if args.dry_run else ""))
        for where, old, new in applied:
            print(f"  {where}\n    − {old.replace(chr(10), ' / ')}\n    + {new.replace(chr(10), ' / ')}")
        if nodes_dirty:
            save(NODES_PATH, root, args.dry_run)
        if pools_dirty:
            save(REACTIVE_PATH, reactive, args.dry_run)
    if cuts:
        print("\n== CUT (not applied — needs a human, removing a node changes the graph)")
        for c in cuts:
            print(f"  ❌ {c}")
    if comments:
        print("\n== COMMENTS")
        for where, verdict, text in comments:
            tag = {"keep": "✅", "edit": "✏️", "cut": "❌"}.get(verdict, "·")
            print(f"  {tag} {where}: {text}")
    if applied and not args.dry_run:
        print("\nnext: powershell -File tools/godot_check/check.ps1   (lint + suite), then rebuild the page")
    return 0


if __name__ == "__main__":
    sys.exit(main())
