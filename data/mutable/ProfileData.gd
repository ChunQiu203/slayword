## Maintains data for the player
extends SerializableData
class_name ProfileData

@export var profile_name: String = ""

@export var profile_total_wins: int = 0
@export var profile_total_losses: int = 0
@export var profile_total_runs: int = 0
@export var profile_character_object_id_to_wins: Dictionary[String, int] = {}
@export var profile_character_object_id_to_losses: Dictionary[String, int] = {}

@export var profile_character_object_id_to_highest_difficulty: Dictionary[String, int] = {}
## 本地战绩册：最近若干局的路线、牌组、遗物与背单词概况。
@export var profile_run_history: Array = []

## 背单词间隔复习状态：word_id -> { "r": int, "i": float, "e": float, "d": int }（次数、间隔小时、因子、下次到期 unix）
@export var profile_vocab_word_states: Dictionary = {}
## 运行时/on-demand API 生成的例句：full word_id -> study_examples 数组（合并进词池，优先于词书 JSON）
@export var profile_vocab_example_overrides: Dictionary = {}
## 每日按顺序预生成例句：在合并词池中的起始下标（循环）；与 profile_vocab_seq_example_last_day 配合每日推进
@export var profile_vocab_seq_example_cursor: int = 0
## 上次完成「顺序预生成」批次的自然日（与 VocabStudy._vocab_calendar_day_id 同格式）
@export var profile_vocab_seq_example_last_day: int = 0

func win_run(character_object_id: String) -> void:
	profile_total_wins += 1
	var character_wins: int = profile_character_object_id_to_wins.get(character_object_id, 0)
	character_wins += 1
	profile_character_object_id_to_wins[character_object_id] = character_wins

func lose_run(character_object_id: String) -> void:
	profile_total_losses += 1
	var character_losses: int = profile_character_object_id_to_losses.get(character_object_id, 0)
	character_losses += 1
	profile_character_object_id_to_losses[character_object_id] = character_losses
