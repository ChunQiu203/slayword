#!/usr/bin/env python3
"""Scan GDScript and scene files for hardcoded text not going through I18N.

Usage:
    python tools/check_i18n.py           # Check .gd files only (recommended)
    python tools/check_i18n.py --all     # Also check .tscn placeholder text
    python tools/check_i18n.py --help    # Show this help
"""

import re
import os
import sys
import io

# Fix Unicode output on Windows
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

SKIP_DIRS = {"addons", "__pycache__", ".godot", "external", "canzhao", "json"}

# .gd patterns to skip (format strings, symbols, single chars, etc.)
SKIP_GD_PATTERNS = [
    r'\.text\s*=\s*"[^"]*%[sd]',       # format strings like "$%d", "%s / %s"
    r'\.text\s*=\s*"[X\d]+',            # "X", "X-3" etc
    r'\.text\s*=\s*"[^\x00-\x7F]{1}"',  # single non-ASCII char (emoji etc)
    r'\.text\s*=\s*"\$',                # price strings
]

# Known placeholder text in .tscn files that's overwritten at runtime
TSCN_PLACEHOLDERS = {
    "Name", "Reward 1", "Reward", "Artifact Name", "Consumable Name",
    "Description ", "Test", "HP:", "[color=green]Dialogue Prompt Rich Text[/color]",
}


def has_cjk(text: str) -> bool:
    for ch in text:
        cp = ord(ch)
        if (0x4E00 <= cp <= 0x9FFF or 0x3400 <= cp <= 0x4DBF or
                0xF900 <= cp <= 0xFAFF or 0x20000 <= cp <= 0x2A6DF):
            return True
    return False


def has_english_words(text: str) -> bool:
    return bool(re.search(r'[A-Za-z]{3,}', text))


def is_excluded_gd_line(line: str) -> bool:
    for pattern in SKIP_GD_PATTERNS:
        if re.search(pattern, line):
            return True
    return False


def check_gd_file(filepath: str) -> list:
    warnings = []
    rel = os.path.relpath(filepath, PROJECT_ROOT).replace("\\", "/")

    basename = os.path.basename(filepath)
    if basename.startswith("test_"):
        return warnings

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            lines = f.readlines()
    except Exception:
        return warnings

    pattern = re.compile(
        r'\.(text|tooltip_text|placeholder_text)\s*=\s*"([^"]*)"'
    )

    for i, line in enumerate(lines, 1):
        if "I18N" in line:
            continue
        if is_excluded_gd_line(line):
            continue

        m = pattern.search(line)
        if m:
            prop = m.group(1)
            value = m.group(2)
            if not value or len(value) < 2:
                continue
            if has_cjk(value) or has_english_words(value):
                warnings.append(
                    f"[WARN] {rel}:{i} — .{prop} = \"{value}\" (should use I18N.tr_key)"
                )

    return warnings


def check_tscn_file(filepath: str) -> list:
    warnings = []
    rel = os.path.relpath(filepath, PROJECT_ROOT).replace("\\", "/")

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        return warnings

    for i, line in enumerate(content.splitlines(), 1):
        m = re.match(r'^text\s*=\s*"([^"]*)"', line.strip())
        if m:
            value = m.group(1)
            if not value or len(value) < 2:
                continue
            if value in TSCN_PLACEHOLDERS:
                continue
            if has_cjk(value) or has_english_words(value):
                warnings.append(
                    f"[WARN] {rel}:{i} — text = \"{value}\" (hardcoded text in scene)"
                )

    return warnings


def main():
    check_tscn = "--all" in sys.argv
    if "--help" in sys.argv or "-h" in sys.argv:
        print(__doc__.strip())
        sys.exit(0)

    all_warnings = []

    for root, dirs, files in os.walk(PROJECT_ROOT):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]

        for f in files:
            filepath = os.path.join(root, f)
            if f.endswith(".gd"):
                all_warnings.extend(check_gd_file(filepath))
            elif f.endswith(".tscn") and check_tscn:
                all_warnings.extend(check_tscn_file(filepath))

    if all_warnings:
        print(f"\nFound {len(all_warnings)} potential i18n issue(s):\n")
        for w in all_warnings:
            print(w)
        print("\nTip: Use I18N.tr_key() for all user-visible text.")
        print("     Add keys to external/locale/zh_CN.json and en_US.json.\n")
        sys.exit(1)
    else:
        print("No i18n issues found.")
        sys.exit(0)


if __name__ == "__main__":
    main()
