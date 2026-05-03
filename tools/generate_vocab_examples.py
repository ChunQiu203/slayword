# -*- coding: utf-8 -*-
"""
使用 OpenAI API 为词书 JSON 批量生成 study_examples（学习页多条例句）。

依赖：Python 3.10+，仅标准库。

配置（任选其一）：
  1) 项目根目录或当前工作目录下的 .env（推荐），见根目录 .env.example
  2) 系统环境变量

.env / 环境变量说明：
  OPENAI_API_KEY          必填
  OPENAI_BASE_URL         选填，如 https://api.openai.com/v1（自动拼 /chat/completions）
  OPENAI_API_BASE         与 OPENAI_BASE_URL 等价（兼容旧名）
  OPENAI_CHAT_COMPLETIONS_URL  选填，完整 Chat Completions URL（若设置则优先于 BASE_URL）
  OPENAI_MODEL            选填，默认 gpt-4o-mini
  DOTENV_PATH             选填，指定 .env 文件绝对路径
  VOCAB_EXAMPLE_DOMAINS   选填，例句领域（逗号分隔，与游戏暂停里勾选、user_settings 合并）

示例：
  python tools/generate_vocab_examples.py data/vocab_books/book_demo_postgraduate.json -o out.json --only-missing
  python tools/generate_vocab_examples.py book.json -o out.json --domains "影视,考研"
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request
from typing import Any, Dict, List, Optional

DEFAULT_API_URL = "https://api.openai.com/v1/chat/completions"
DEFAULT_MODEL = "gpt-4o-mini"

SYSTEM_PROMPT_BASE = """你是英语学习词书编辑。用户会给出词条的英文 headword、中文释义、以及游戏里的默写题干说明。
请生成 2～4 条英文例句，尽量覆盖不同义项或用法；每条配一行简短中文 gloss 标明该句侧重的义（可与释义栏对应）。
每条必须另附 sentence_zh：对该英文例句的完整、自然的中文翻译（整句译意，不要只重复 gloss）。
例句里必须自然包含该英文单词（可用适当词形变化）。不要编造不存在的专有名词剧情。
只输出 JSON 对象，格式严格如下（不要 markdown 代码围栏）：
{"examples":[{"sentence":"英文例句","gloss":"中文义项提示","sentence_zh":"该句完整中文翻译"},...]}
"""

# 与 Godot 暂停菜单预设 id 一致（供 .env / CLI 使用 id 或中文）
PRESET_ID_TO_ZH: Dict[str, str] = {
    "film_tv": "影视",
    "anime": "动漫 / 二次元",
    "exam_style": "考研 / 真题风",
    "daily": "日常口语",
    "news": "新闻 / 评论",
    "game_scifi": "游戏 / 科幻",
}


def _split_domain_csv(s: str) -> List[str]:
    s = (s or "").strip()
    if not s:
        return []
    return [p.strip() for p in re.split(r"[,，;；|]+", s) if p.strip()]


def _expand_domain_token(t: str) -> str:
    x = (t or "").strip()
    if not x:
        return ""
    return PRESET_ID_TO_ZH.get(x, x)


def _default_user_settings_path() -> Optional[str]:
    p = os.path.join(_repo_root(), "external", "user_settings.json")
    return p if os.path.isfile(p) else None


def _load_user_settings_domain_prefs(path: Optional[str]) -> tuple[List[str], str]:
    if not path or not os.path.isfile(path):
        return [], ""
    with open(path, encoding="utf-8") as f:
        data: Any = json.load(f)
    if not isinstance(data, dict):
        return [], ""
    tags: List[str] = []
    raw_tags = data.get("settings_vocab_example_domain_tags", [])
    if isinstance(raw_tags, list):
        for it in raw_tags:
            if isinstance(it, str) and it.strip():
                tags.append(it.strip())
    custom = str(data.get("settings_vocab_example_domain_custom", "") or "").strip()
    return tags, custom


def _merge_domain_hints(
    cli_domains: Optional[str],
    env_domains: str,
    user_settings_path: Optional[str],
) -> str:
    """拼出注入 system 的中文说明；若传入 CLI 非空则仅用 CLI。"""
    if cli_domains and str(cli_domains).strip():
        parts = _split_domain_csv(str(cli_domains))
        shown = [_expand_domain_token(p) for p in parts]
        shown = [x for x in shown if x]
        if not shown:
            return ""
        return (
            "用户希望例句语境优先贴近："
            + "、".join(shown)
            + "。（在自然地道前提下尽量体现；无法兼顾时以词语准确用法为准）"
        )
    pieces: List[str] = []
    for chunk in _split_domain_csv(env_domains):
        y = _expand_domain_token(chunk)
        if y and y not in pieces:
            pieces.append(y)
    utags, ucustom = _load_user_settings_domain_prefs(user_settings_path)
    for tid in utags:
        y = _expand_domain_token(tid)
        if y and y not in pieces:
            pieces.append(y)
    if ucustom:
        for p in _split_domain_csv(ucustom) or [ucustom]:
            if p and p not in pieces:
                pieces.append(p)
    if not pieces:
        return ""
    return (
        "用户希望例句语境优先贴近："
        + "、".join(pieces)
        + "。（在自然地道前提下尽量体现；无法兼顾时以词语准确用法为准）"
    )


def build_system_prompt(domain_line: str) -> str:
    if not (domain_line or "").strip():
        return SYSTEM_PROMPT_BASE
    return SYSTEM_PROMPT_BASE + "\n\n【例句语境偏好】" + domain_line.strip()


def _parse_dotenv_line(line: str) -> Optional[tuple[str, str]]:
    s = line.strip()
    if not s or s.startswith("#"):
        return None
    if "=" not in s:
        return None
    key, _, val = s.partition("=")
    key = key.strip()
    if not key:
        return None
    val = val.strip()
    if len(val) >= 2 and val[0] == val[-1] and val[0] in ("\"", "'"):
        val = val[1:-1]
    return (key, val)


def _load_dotenv_file(path: str) -> None:
    with open(path, encoding="utf-8") as f:
        for line in f:
            parsed = _parse_dotenv_line(line)
            if parsed is None:
                continue
            k, v = parsed
            if k not in os.environ:
                os.environ[k] = v


def _script_dir() -> str:
    return os.path.dirname(os.path.abspath(__file__))


def _repo_root() -> str:
    return os.path.dirname(_script_dir())


def _find_dotenv_path() -> Optional[str]:
    dotenv_path = os.environ.get("DOTENV_PATH", "").strip()
    if dotenv_path and os.path.isfile(dotenv_path):
        return dotenv_path
    here = _repo_root()
    cwd = os.getcwd()
    for candidate in (
        os.path.join(cwd, ".env"),
        os.path.join(here, ".env"),
    ):
        if os.path.isfile(candidate):
            return candidate
    return None


def _load_dotenv_if_present() -> None:
    path = _find_dotenv_path()
    if path:
        _load_dotenv_file(path)


def _resolve_api_url(cli_api_url: Optional[str]) -> str:
    if cli_api_url:
        return cli_api_url.rstrip("/")
    full = os.environ.get("OPENAI_CHAT_COMPLETIONS_URL", "").strip()
    if full:
        return full.rstrip("/")
    base = (
        os.environ.get("OPENAI_BASE_URL", "").strip()
        or os.environ.get("OPENAI_API_BASE", "").strip()
    )
    if base:
        base = base.rstrip("/")
        if base.endswith("/chat/completions"):
            return base
        return base + "/chat/completions"
    return DEFAULT_API_URL


def _strip_json_fence(text: str) -> str:
    t = text.strip()
    if t.startswith("```"):
        lines = t.split("\n")
        if lines and lines[0].strip().startswith("```"):
            lines = lines[1:]
        if lines and lines[-1].strip() == "```":
            lines = lines[:-1]
        t = "\n".join(lines).strip()
    return t


def _parse_llm_json(text: str) -> Dict[str, Any]:
    t = _strip_json_fence(text)
    return json.loads(t)


def _call_chat(
    api_key: str,
    api_url: str,
    model: str,
    system: str,
    user: str,
    timeout: int,
) -> str:
    payload: Dict[str, Any] = {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        "temperature": 0.65,
        "response_format": {"type": "json_object"},
    }
    data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(
        api_url,
        data=data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            raw = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {e.code}: {body}") from e
    try:
        return raw["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError) as ex:
        raise RuntimeError(f"Unexpected API response: {raw!r}") from ex


def _normalize_examples(raw: Any) -> List[Dict[str, str]]:
    if not isinstance(raw, list):
        return []
    out: List[Dict[str, str]] = []
    for item in raw:
        if isinstance(item, str):
            s = item.strip()
            if s:
                out.append({"sentence": s, "gloss": "", "sentence_zh": ""})
        elif isinstance(item, dict):
            sent = str(
                item.get("sentence") or item.get("en") or item.get("text") or ""
            ).strip()
            if not sent:
                continue
            gloss = str(
                item.get("gloss") or item.get("meaning") or item.get("sense") or ""
            ).strip()
            zh = str(
                item.get("sentence_zh")
                or item.get("zh")
                or item.get("translation")
                or item.get("cn")
                or item.get("chinese")
                or ""
            ).strip()
            out.append({"sentence": sent, "gloss": gloss, "sentence_zh": zh})
    return out


def _word_needs_examples(word: Dict[str, Any], only_missing: bool) -> bool:
    if not only_missing:
        return True
    ex = word.get("study_examples")
    if ex is None:
        return True
    if isinstance(ex, list) and len(ex) > 0:
        return False
    return True


def _build_user_payload(word: Dict[str, Any]) -> str:
    payload = {
        "id": word.get("id"),
        "study_headword": word.get("study_headword", ""),
        "study_meaning": word.get("study_meaning", ""),
        "answers": word.get("answers", []),
        "prompt_plain": re.sub(
            r"\[/?center\]", "", str(word.get("prompt", "")), flags=re.I
        ).strip(),
    }
    return json.dumps(payload, ensure_ascii=False)


def generate_for_word(
    word: Dict[str, Any],
    api_key: str,
    api_url: str,
    model: str,
    timeout: int,
    system_prompt: str,
) -> List[Dict[str, str]]:
    content = _call_chat(
        api_key,
        api_url,
        model,
        system_prompt,
        _build_user_payload(word),
        timeout=timeout,
    )
    parsed = _parse_llm_json(content)
    examples = _normalize_examples(parsed.get("examples"))
    if not examples:
        raise ValueError(f"模型未返回有效 examples: {content[:500]}")
    return examples


def main() -> int:
    # 在解析参数前加载 .env，使命令行默认值能读到 OPENAI_*（除非显式跳过）
    if "--no-dotenv" not in sys.argv:
        _load_dotenv_if_present()

    p = argparse.ArgumentParser(description="用 OpenAI API 为词书生成 study_examples")
    p.add_argument("input_json", help="输入词书 JSON 路径")
    p.add_argument(
        "-o",
        "--output",
        required=True,
        help="输出词书 JSON 路径（不会覆盖输入，除非你显式写成同一路径）",
    )
    p.add_argument(
        "--model",
        default=None,
        help="模型名；默认读 OPENAI_MODEL 或 gpt-4o-mini",
    )
    p.add_argument(
        "--api-url",
        default=None,
        help="完整 Chat Completions URL；默认读 OPENAI_CHAT_COMPLETIONS_URL 或由 OPENAI_BASE_URL 拼接",
    )
    p.add_argument(
        "--no-dotenv",
        action="store_true",
        help="不加载 .env（仅用当前进程已有环境变量）",
    )
    p.add_argument(
        "--domains",
        default=None,
        help="例句领域，逗号分隔；若指定则不再合并 .env / user_settings（独占）",
    )
    p.add_argument(
        "--user-settings",
        default=None,
        help="user_settings.json 路径；默认尝试项目 external/user_settings.json",
    )
    p.add_argument(
        "--no-user-settings",
        action="store_true",
        help="不读取 user_settings.json（仅用 .env / CLI）",
    )
    p.add_argument(
        "--only-missing",
        action="store_true",
        help="仅处理尚无 study_examples 的词条",
    )
    p.add_argument("--limit", type=int, default=0, help="最多处理多少条（0 表示全部）")
    p.add_argument("--delay", type=float, default=0.35, help="每条请求之间的秒数，防限流")
    p.add_argument("--timeout", type=int, default=120, help="单次 HTTP 超时秒数")
    args = p.parse_args()

    model = (args.model or os.environ.get("OPENAI_MODEL") or DEFAULT_MODEL).strip()
    api_url = _resolve_api_url(args.api_url)

    api_key = os.environ.get("OPENAI_API_KEY", "").strip()
    if not api_key:
        print(
            "请设置 OPENAI_API_KEY（可在项目根目录或当前目录的 .env 中配置，参见 .env.example）",
            file=sys.stderr,
        )
        return 1

    us_path: Optional[str] = None
    if not args.no_user_settings:
        us_path = args.user_settings or _default_user_settings_path()

    domain_line = _merge_domain_hints(
        args.domains,
        os.environ.get("VOCAB_EXAMPLE_DOMAINS", ""),
        us_path,
    )
    system_prompt = build_system_prompt(domain_line)
    if domain_line:
        print("例句领域偏好：" + domain_line[:200] + ("…" if len(domain_line) > 200 else ""), flush=True)

    with open(args.input_json, encoding="utf-8") as f:
        root: Dict[str, Any] = json.load(f)
    words = root.get("words")
    if not isinstance(words, list):
        print("词书根对象缺少 words 数组", file=sys.stderr)
        return 1

    done = 0
    for i, w in enumerate(words):
        if not isinstance(w, dict):
            continue
        if args.limit and done >= args.limit:
            break
        if not _word_needs_examples(w, args.only_missing):
            continue
        wid = w.get("id", f"#{i}")
        print(f"[{done + 1}] 生成例句: {wid} …", flush=True)
        try:
            examples = generate_for_word(
                w, api_key, api_url, model, args.timeout, system_prompt
            )
        except Exception as e:
            print(f"  失败: {e}", file=sys.stderr)
            return 2
        w["study_examples"] = examples
        done += 1
        if args.delay > 0:
            time.sleep(args.delay)

    out_path = args.output
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(root, f, ensure_ascii=False, indent="\t")
        f.write("\n")
    print(f"已写入 {done} 条更新 -> {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())