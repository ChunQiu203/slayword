## Maintains user settings.
## Loaded automatically via FileLoader.load_user_settings() and stored in Global.
## NOTE: None of these settings are actually hooked up to anything. Add more variables depending
## on the needs of your project
extends SerializableData
class_name UserSettingsData

## Language
@export var settings_language: String = "en"

## Resolution
@export var settings_window_size: Vector2 = Vector2(1200, 700)

## Volume
@export var settings_audio_master_volume: int = 10
@export var settings_audio_music_volume: int = 10
@export var settings_audio_effects_volume: int = 10

## 启用的词书 id（合并出题池）。默认：内置小词表 + NETEM 考研5530（见 data/vocab_books/book_netem_full.json）。
@export var settings_vocab_enabled_book_ids: Array[String] = ["builtin_default", "netem_full"]
## 战斗中出牌前的复习题型：spell / meaning / mc4 / recall（已由 settings_vocab_review_modes_enabled 取代；保留作旧存档兼容）。
@export var settings_vocab_combat_review_mode: String = "spell"
## 新词学习流水线启用的环节 id：en2zh / zh2en / spell / dictation（勾选顺序按固定流水线排列）。
@export var settings_vocab_learn_steps_enabled: Array[String] = ["en2zh", "zh2en", "spell", "dictation"]
## 出牌复习时在哪些题型中随机抽一种（至少勾选一个）。
@export var settings_vocab_review_modes_enabled: Array[String] = ["spell", "meaning", "mc4", "recall"]
## 每个自然日从合并词池中按顺序取多少「未 learned」词作为当日优先新词（0=不启用优先队列，行为与旧版一致）。
@export var settings_vocab_daily_new_words: int = 15
## 自然日内从「到期复习」池中最多参与出牌复习的词数（0=不限制）。按日期固定随机子集，第二天会换一批。
@export var settings_vocab_daily_due_cap: int = 30
## 每个自然日从合并词池中按固定顺序取多少词，用 API 预生成例句并写入 user://vocab_example_cache.json（0=不跑每日批次）。
@export var settings_vocab_daily_ordered_example_words: int = 20

## 离线生成例句（tools/generate_vocab_examples.py）时的领域偏好：预设 id，见新开局界面勾选。
@export var settings_vocab_example_domain_tags: Array[String] = ["game_scifi", "daily"]
## 补充说明（自由文本，可与勾选叠加写入 user_settings.json 供脚本读取）。
@export var settings_vocab_example_domain_custom: String = ""

## 游戏内调用 OpenAI 兼容 API 生成例句（留空则依次用系统环境变量、项目根 res://.env、DOTENV_PATH 指向的文件中的 OPENAI_API_KEY）。
@export var settings_openai_api_key: String = ""
@export var settings_openai_base_url: String = "https://api.openai.com/v1"
@export var settings_openai_model: String = "gpt-4o-mini"
## 已废弃：出牌缺例句时是否联网补全（现改为「只要解析到 API Key 即自动补全」，保留字段以兼容旧存档）。
@export var settings_vocab_fetch_examples_on_review: bool = true

func _get_native_properties() -> Dictionary:
	return {
		"settings_window_size": Vector2()
		}
