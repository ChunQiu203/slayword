extends Node

const DEFAULT_LOCALE: String = "zh_CN"
const LOCALE_DIR: String = "external/locale/"

var current_locale: String = DEFAULT_LOCALE
var _translations: Dictionary = {}

signal locale_changed(locale: String)

func _ready() -> void:
	load_locale(DEFAULT_LOCALE)

func load_locale(locale: String) -> void:
	current_locale = _normalize_locale(locale)
	_translations = {}
	_merge_translations(FileLoader.load_json(LOCALE_DIR, current_locale + ".json"))
	_merge_translations(FileLoader.load_json(LOCALE_DIR, current_locale + "_data.json"))
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
