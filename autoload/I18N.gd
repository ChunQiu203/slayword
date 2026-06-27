extends Node

const DEFAULT_LOCALE: String = "zh_CN"
const LOCALE_DIR: String = "external/locale/"

var current_locale: String = DEFAULT_LOCALE
var _translations: Dictionary = {}

signal locale_changed(locale: String)

func _ready() -> void:
	load_locale(DEFAULT_LOCALE, false)

func load_locale(locale: String, persist_setting: bool = true) -> void:
	current_locale = _normalize_locale(locale)
	_translations = {}
	# Clear JSON cache to force reload of locale files
	FileLoader._cached_json.clear()
	_merge_translations(FileLoader.load_json(LOCALE_DIR, current_locale + ".json"))
	_merge_translations(FileLoader.load_json(LOCALE_DIR, current_locale + "_data.json"))
	if persist_setting:
		Global.user_settings_data.settings_language = current_locale
		FileLoader.save_user_settings()
	locale_changed.emit(current_locale)

func toggle_locale() -> void:
	if current_locale == "zh_CN":
		load_locale("en_US")
	else:
		load_locale("zh_CN")

func tr_key(key: String, params: Array = []) -> String:
	var template: String = str(_translations.get(key, key))
	if len(params) > 0:
		return template.format(params)
	return template

func tr_enum(prefix: String, enum_key: String) -> String:
	return tr_key(prefix + "." + enum_key.to_lower())

func tr_data(object_id: String, field: String, fallback: String, params: Array = []) -> String:
	var key: String = "data.{0}.{1}".format([object_id, field])
	var template: String = str(_translations.get(key, fallback))
	if len(params) > 0:
		return template.format(params)
	return template

func _normalize_locale(locale: String) -> String:
	match locale:
		"zh", "zh_CN":
			return "zh_CN"
		"en", "en_US":
			return "en_US"
		_:
			return DEFAULT_LOCALE

func _merge_translations(source: Dictionary) -> void:
	for key: String in source.keys():
		_translations[key] = source[key]

## 统一翻译入口：所有游戏数据（卡牌/敌人/遗物/消耗品）必须通过这些方法获取翻译

func get_card_name(card_data: CardData) -> String:
	return tr_data(card_data.object_id, "card_name", card_data.card_name)

func get_card_description(card_data: CardData) -> String:
	return tr_data(card_data.object_id, "card_description", card_data.card_description)

func get_enemy_name(enemy_data: EnemyData) -> String:
	return tr_data(enemy_data.object_id, "enemy_name", enemy_data.enemy_name)

func get_artifact_name(artifact_data: ArtifactData) -> String:
	return tr_data(artifact_data.object_id, "artifact_name", artifact_data.artifact_name)

func get_artifact_description(artifact_data: ArtifactData) -> String:
	return tr_data(artifact_data.object_id, "artifact_description", artifact_data.artifact_description)

func get_consumable_name(consumable_data: ConsumableData) -> String:
	return tr_data(consumable_data.object_id, "consumable_name", consumable_data.consumable_name)

func get_consumable_description(consumable_data: ConsumableData) -> String:
	return tr_data(consumable_data.object_id, "consumable_description", consumable_data.consumable_description)
