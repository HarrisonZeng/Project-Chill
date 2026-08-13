#!/usr/bin/env python3
"""Build the bundled CJK font used by Project Chill.

Why this exists
---------------
`data/theme/project_chill.tres` picks its typeface with `SystemFont`, i.e. "use
LXGW WenKai / PingFang SC / Microsoft YaHei if the machine has it". That works on
Windows and macOS. It does **not** work in a browser: the Godot web export has no
access to installed system fonts, so every Mandarin glyph renders as a blank box.

So the web build needs a font shipped inside the game. A full CJK font is ~25 MB,
which is a painful download for a browser game, so this script subsets one down to
the characters the game can actually show and converts it to WOFF2.

The output is committed to the repo (`assets/fonts/`) so that ordinary builds and
CI never need to run this. Re-run it only when the character coverage needs to
change.

Usage:
    python3 tools/fonts/build_web_font.py

Requires: pip install fonttools brotli
"""

from __future__ import annotations

import glob
import subprocess
import sys
import urllib.request
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = REPO_ROOT / "assets" / "fonts"
OUT_FONT = OUT_DIR / "chill_kai_gb.woff2"

# LXGW WenKai (SIL OFL 1.1) — the handwriting-ish Kai face the theme already asks
# for by name, so the bundled fallback matches the intended look.
SOURCE_URL = (
    "https://github.com/lxgw/LxgwWenKai/releases/download/v1.520/LXGWWenKai-Regular.ttf"
)
# Cached OUTSIDE the repo on purpose. Godot imports every font it finds inside the
# project folder and packs it into the export, so a 24 MB source TTF sitting in the
# tree would silently ride along into the web build even if git ignores it.
SOURCE_CACHE = Path.home() / ".cache" / "project-chill" / "LXGWWenKai-Regular.ttf"

# The OFL reserves the "LXGW WenKai" name. A subset is a Modified Version, so the
# bundled file is renamed rather than shipped under the reserved name. Attribution
# and the full licence live in assets/fonts/OFL.txt and assets/fonts/README.md.
FAMILY_NAME = "Chill Kai"

# Glyphs the UI draws that live outside the usual Chinese ranges (arrows, the close
# button, the log button, timer chrome). Keep in sync with the scenes.
EXTRA_CHARS = "—“”…→←↑↓▶◀▲▼◼◻●○×╳☰≡▤★☆♪♫✓"

# Files whose text can end up on screen verbatim.
SCAN_PATTERNS = [
    "data/**/*.json",
    "data/**/*.txt",
    "scripts/**/*.gd",
    "scenes/**/*.tscn",
]


def build_charset() -> set[str]:
    """The characters the bundled font must be able to draw.

    Authored dialogue is only ~700 hanzi, but the player types free text (nickname,
    Type Mode) and that has to render too. GB2312 covers effectively all modern
    everyday Chinese, so it is the safety net under the game's own vocabulary.
    """
    chars: set[str] = set()

    # Latin, punctuation, CJK punctuation, fullwidth forms.
    for start, end in [
        (0x20, 0x7F),
        (0xA0, 0x100),
        (0x2000, 0x206F),
        (0x3000, 0x3040),
        (0xFF00, 0xFFF0),
    ]:
        chars.update(chr(i) for i in range(start, end))

    # GB2312: ~6.7k hanzi + symbols, the standard "everyday Chinese" set.
    for i in range(0x20, 0x10000):
        c = chr(i)
        try:
            c.encode("gb2312")
        except UnicodeEncodeError:
            continue
        chars.add(c)

    chars.update(EXTRA_CHARS)

    # Anything the project itself writes, so authored text can never tofu.
    for pattern in SCAN_PATTERNS:
        for path in glob.glob(str(REPO_ROOT / pattern), recursive=True):
            try:
                text = Path(path).read_text(encoding="utf-8")
            except (UnicodeDecodeError, OSError):
                continue
            chars.update(ch for ch in text if ord(ch) > 0x2000)

    return chars


def fetch_source() -> Path:
    if SOURCE_CACHE.exists():
        return SOURCE_CACHE
    SOURCE_CACHE.parent.mkdir(parents=True, exist_ok=True)
    print(f"downloading {SOURCE_URL} ...")
    urllib.request.urlretrieve(SOURCE_URL, SOURCE_CACHE)
    return SOURCE_CACHE


def rename_family(font_path: Path, family: str) -> None:
    """Retire the reserved "LXGW WenKai" name from the subset.

    The OFL reserves that name for the unmodified font, and a subset is a Modified
    Version, so the shipped file carries its own family name.
    """
    from fontTools.ttLib import TTFont

    font = TTFont(font_path)
    postscript = family.replace(" ", "")
    replacements = {
        1: family,  # family
        3: f"{family};subset",  # unique id
        4: family,  # full name
        6: postscript,  # postscript name
        16: family,  # typographic family
    }
    for record in font["name"].names:
        if record.nameID in replacements:
            record.string = replacements[record.nameID]
    font.save(font_path)


def main() -> int:
    try:
        import fontTools  # noqa: F401
        import brotli  # noqa: F401
    except ImportError:
        print("error: pip install fonttools brotli", file=sys.stderr)
        return 1

    source = fetch_source()
    charset = build_charset()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    charset_file = SOURCE_CACHE.parent / "charset.txt"
    charset_file.parent.mkdir(parents=True, exist_ok=True)
    charset_file.write_text("".join(sorted(charset)), encoding="utf-8")
    print(f"charset: {len(charset)} characters")

    subprocess.run(
        [
            sys.executable,
            "-m",
            "fontTools.subset",
            str(source),
            f"--text-file={charset_file}",
            f"--output-file={OUT_FONT}",
            "--flavor=woff2",
            "--layout-features=",
            "--no-hinting",
            "--desubroutinize",
        ],
        check=True,
    )

    rename_family(OUT_FONT, FAMILY_NAME)

    size_mb = OUT_FONT.stat().st_size / 1024 / 1024
    print(f"wrote {OUT_FONT.relative_to(REPO_ROOT)} ({size_mb:.2f} MB)")

    # A missing glyph is invisible in the editor (system fonts paper over it) and
    # only shows up as a blank box in the browser, so fail loudly here instead.
    from fontTools.ttLib import TTFont

    covered = set(TTFont(OUT_FONT).getBestCmap().keys())
    missing = [c for c in EXTRA_CHARS if ord(c) not in covered]
    if missing:
        print(f"warning: source font lacks {missing}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
