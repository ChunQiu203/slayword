# -*- coding: utf-8 -*-
"""
Build word→pos mapping from json/ exam vocab files,
then add study_pos to vocab book files that are missing it.

Usage:
    python tools/add_pos_to_books.py
"""

import json
import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(SCRIPT_DIR)

JSON_DIR = os.path.join(PROJECT_DIR, "json")
VOCAB_BOOKS_DIR = os.path.join(PROJECT_DIR, "data", "vocab_books")
VOCAB_WORDS_FILE = os.path.join(PROJECT_DIR, "data", "vocab_words.json")

# ── POS normalization (mirrors VocabStudy._map_pos_abbrev) ─────────────────

# Standard abbreviation mapping
_POS_ABBREV: dict[str, str] = {
    # Adjectives
    "a": "adj", "adj": "adj",
    # Adverbs
    "ad": "adv", "adv": "adv",
    # Nouns
    "n": "n",
    # Verbs (vi/vt → v)
    "v": "v", "vi": "v", "vt": "v",
    # Prepositions
    "prep": "prep",
    # Conjunctions
    "conj": "conj", "conjunction": "conj",
    # Pronouns
    "pron": "pron",
    # Interjections
    "int": "int", "interjection": "int",
    # Articles
    "art": "art", "article": "art", "indefinite article": "art",
    # Auxiliary / modal
    "aux": "aux", "modal verb": "aux",
    # Numerals
    "num": "num",
    # Abbreviations
    "abbr": "abbr",
    # Determiners
    "determiner": "det",
    # Skip garbage
    "neg": None, "mar": None,
}

# Tokens to skip entirely (garbage markers that shouldn't contribute to pos)
_SKIP_BLACKLIST: set[str] = {"neg", "mar"}

# CJK Unicode ranges to detect Chinese/garbage characters
_CJK_RANGES = [
    (0x4E00, 0x9FFF),   # CJK Unified Ideographs
    (0x3400, 0x4DBF),   # CJK Unified Ideographs Extension A
    (0x3000, 0x303F),   # CJK Symbols and Punctuation
    (0xFF00, 0xFFEF),   # Halfwidth and Fullwidth Forms
    (0x2E80, 0x2EFF),   # CJK Radicals Supplement
    (0xFE30, 0xFE4F),   # CJK Compatibility Forms
]


def _contains_cjk(s: str) -> bool:
    """Check if string contains any CJK or fullwidth characters."""
    for ch in s:
        cp = ord(ch)
        for lo, hi in _CJK_RANGES:
            if lo <= cp <= hi:
                return True
    return False


def normalize_pos_type(raw: str) -> set[str]:
    """
    Normalize a raw type string from json/ translations[].type
    into a set of standard POS abbreviations (e.g. {"adj", "n", "v"}).

    Mirrors VocabStudy._normalize_pos_type_into / _map_pos_abbrev.
    """
    cleaned = raw.strip().lower()
    if not cleaned:
        return set()

    # Reject entries with CJK or fullwidth garbage
    if _contains_cjk(cleaned):
        return set()

    # Reject entries that are just brackets/explainers like "[数]n"
    if cleaned.startswith("[") or cleaned.startswith("("):
        return set()

    # Split compound types by & and /
    tokens = []
    for part in re.split(r"[&/]", cleaned):
        part = part.strip()
        if part:
            tokens.append(part)

    result: set[str] = set()
    for token in tokens:
        # Remove parenthetical annotations like "n(pl)"
        token = re.sub(r"\(.*?\)", "", token).strip()
        if not token:
            continue
        abbrev = _POS_ABBREV.get(token)
        if abbrev:
            result.add(abbrev)
        # Unknown tokens are silently ignored (as in GDScript)

    return result


# ── Phase A: Build word→pos mapping from json/ files ──────────────────────


def build_pos_map() -> dict[str, str]:
    """Scan all json/*-顺序.json files and build {word_lower: pos_str}."""
    pos_map: dict[str, set[str]] = {}

    json_files = sorted(
        [f for f in os.listdir(JSON_DIR) if f.endswith(".json")],
    )
    if not json_files:
        print("ERROR: No JSON files found in", JSON_DIR)
        sys.exit(1)

    for fname in json_files:
        fpath = os.path.join(JSON_DIR, fname)
        with open(fpath, encoding="utf-8") as f:
            data = json.load(f)

        if not isinstance(data, list):
            print(f"  skip {fname}: not a top-level array")
            continue

        for entry in data:
            if not isinstance(entry, dict):
                continue
            word = (entry.get("word") or "").strip().lower()
            if not word:
                continue
            translations = entry.get("translations")
            if not isinstance(translations, list):
                continue

            types: set[str] = set()
            for t in translations:
                if not isinstance(t, dict):
                    continue
                tp_raw = (t.get("type") or "").strip()
                types |= normalize_pos_type(tp_raw)

            if word in pos_map:
                pos_map[word] |= types
            else:
                pos_map[word] = types

    # Convert sets to formatted strings: e.g. "adj.n.v."
    result: dict[str, str] = {}
    for word, types in pos_map.items():
        if types:
            result[word] = ".".join(sorted(types)) + "."
        else:
            result[word] = ""
    return result


# ── Phase B: Apply pos_map to target files ────────────────────────────────


def add_pos_to_vocab_book(filepath: str, pos_map: dict[str, str]):
    """Read a vocab book JSON, add study_pos to each word, write back."""
    with open(filepath, encoding="utf-8") as f:
        book = json.load(f)

    words = book.get("words")
    if not isinstance(words, list):
        print(f"  skip {filepath}: no 'words' array")
        return

    matched = 0
    total = 0
    for w in words:
        if not isinstance(w, dict):
            continue
        total += 1
        headword = (w.get("study_headword") or "").strip().lower()
        pos = pos_map.get(headword, "")
        w["study_pos"] = pos
        if pos:
            matched += 1

    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(book, f, ensure_ascii=False, indent="\t")

    pct = (matched / total * 100) if total > 0 else 0
    print(f"  {os.path.basename(filepath)}: {matched}/{total} matched ({pct:.1f}%)")


def add_pos_to_vocab_words(filepath: str, pos_map: dict[str, str]):
    """Read vocab_words.json (flat {"words": [...]}), add study_pos, write back."""
    with open(filepath, encoding="utf-8") as f:
        data = json.load(f)

    words = data.get("words")
    if not isinstance(words, list):
        print(f"  skip {filepath}: no 'words' array")
        return

    matched = 0
    total = 0
    for w in words:
        if not isinstance(w, dict):
            continue
        total += 1
        headword = (w.get("study_headword") or "").strip().lower()
        pos = pos_map.get(headword, "")
        w["study_pos"] = pos
        if pos:
            matched += 1

    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent="\t")

    pct = (matched / total * 100) if total > 0 else 0
    print(f"  {os.path.basename(filepath)}: {matched}/{total} matched ({pct:.1f}%)")


# ── Main ──────────────────────────────────────────────────────────────────


def main() -> int:
    print("Phase A: Building word→pos map from json/ files...")
    pos_map = build_pos_map()
    print(f"  → {len(pos_map)} unique words with pos info")

    print("\nPhase B: Adding study_pos to target files...")
    targets = [
        os.path.join(VOCAB_BOOKS_DIR, "book_netem_full.json"),
        os.path.join(VOCAB_BOOKS_DIR, "book_demo_postgraduate.json"),
    ]
    for fpath in targets:
        if os.path.exists(fpath):
            add_pos_to_vocab_book(fpath, pos_map)
        else:
            print(f"  WARNING: not found: {fpath}")

    if os.path.exists(VOCAB_WORDS_FILE):
        add_pos_to_vocab_words(VOCAB_WORDS_FILE, pos_map)
    else:
        print(f"  WARNING: not found: {VOCAB_WORDS_FILE}")

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
