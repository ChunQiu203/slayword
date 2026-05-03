# -*- coding: utf-8 -*-
"""Convert NETEM netem_full_list.json -> Slayword vocab book JSON.
Source: https://github.com/exam-data/NETEMVocabulary (data: CC BY-NC-SA 4.0)
"""
import json
import re
import sys


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: convert_netem_to_book.py <netem_full_list.json> <out_book.json>")
        return 1
    src, dst = sys.argv[1], sys.argv[2]
    with open(src, encoding="utf-8") as f:
        raw = json.load(f)
    if not isinstance(raw, dict) or not raw:
        print("Invalid root")
        return 1
    arr = next(iter(raw.values()))
    if not isinstance(arr, list):
        print("Invalid array")
        return 1
    words_out = []
    for row in arr:
        if not isinstance(row, dict):
            continue
        idx = row.get("序号")
        w = (row.get("单词") or "").strip()
        if not w:
            continue
        meaning = (row.get("释义") or "").strip().replace("\n", " ")
        other = row.get("其他拼写")
        answers = [w.lower()]
        if other is not None and str(other).strip():
            for part in re.split(r"[/、,，|]", str(other)):
                p = part.strip().lower()
                if p and p not in answers:
                    answers.append(p)
        try:
            wid = "n%05d" % int(idx)
        except (TypeError, ValueError):
            wid = re.sub(r"\W+", "_", w)[:48]
        prompt = (
            "[center]释义：" + meaning + "\n请写出对应英文单词[/center]"
        )
        words_out.append(
            {
                "id": wid,
                "study_headword": w,
                "study_meaning": meaning,
                "prompt": prompt,
                "answers": answers,
            }
        )
    out = {
        "book_id": "netem_full",
        "book_name": "NETEM 考研5530词频（数据：CC BY-NC-SA 4.0，exam-data/NETEMVocabulary）",
        "words": words_out,
    }
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(out, f, ensure_ascii=False, indent="\t")
    print("Wrote", len(words_out), "entries ->", dst)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
