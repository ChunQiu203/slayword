已随仓库打包：book_netem_full.json（NETEM 5530，见 NETEM_ATTRIBUTION.txt）
================================================================

词书 JSON 格式（与内置、导入共用）
================================

每个词书一个 .json 文件，根对象字段：

  book_id   （必填）唯一 ID，仅字母数字与下划线，例如 kaoyan_core_2026
  book_name （可选）显示名
  words     （必填）词条数组

每个词条：

  id             （必填）本书内唯一；运行时会变成「book_id:id」存入复习状态，避免与别的书冲突
  prompt         （必填）题干，可用 \\n 换行；支持 RichText BBCode（与 WordReviewOverlay 一致）
  answers        （必填）字符串数组，任一命中即算对（去首尾空格、英文不区分大小写）
  answer         （可选）单个字符串，等价于 answers: [answer]
  study_headword （可选）英文单词，学习面板标题
  study_meaning  （可选）中文释义
  study_phonetic （可选）音标，例如 /əˈbændən/，学习面板灰色显示
  study_pos      （可选）词性，例如 v./n./adj.，学习面板灰色显示
  study_examples （可选）例句数组，详见下方

放置位置
--------

  打包进游戏：res://data/vocab_books/*.json（随版本发布考研/专业词表等）
  运行时导入：写入 user://vocab_books/<book_id>.json（见 VocabStudy.import_book_from_json_text）

启用哪些词书：UserSettingsData.settings_vocab_enabled_book_ids
  默认含 "builtin_default"（对应 res://data/vocab_words.json 旧版小词表）
  可追加 demo_postgraduate 等 book_id；合并后去重，后者覆盖同全名 id。

程序化 API（GDScript）
--------------------
  VocabStudy.reload_from_settings()
  VocabStudy.import_book_from_json_text(json_string, overwrite=true) -> book_id 或 ""
  VocabStudy.import_book_from_user_absolute_path("C:/path/book.json")  # 桌面
  VocabStudy.list_known_books()  # 元数据数组，供设置 UI
  VocabStudy.set_enabled_vocab_books(["builtin_default", "demo_postgraduate"])

移动端：用系统文件选择器读入 UTF-8 文本后调 import_book_from_json_text；写入 user://vocab_books/。

json/ 目录顺序词库（初中/高中/CET4/CET6/考研/托福/SAT）
----------------------------------------------------------
格式为 JSON 数组，每项 {"word": "...", "translations": [{"translation": "...", "type": "v"}]}。
VocabStudy 自动将 translations[].type 提取为词性（study_pos），无需手动转换。
