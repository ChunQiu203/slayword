extends BaseShopButton

@onready var button: Button = $VBox/Button
@onready var description_label: RichTextLabel = $VBox/Description

func _ready():
	button.button_up.connect(_on_button_up)
	_style_shop_button()

func init(_action_on_click: BaseAction) -> void:
	custom_minimum_size = Vector2(280, 132)
	_style_shop_button()
	if price_label != null:
		price_label.offset_top = 0
		price_label.offset_bottom = 0
		price_label.offset_left = 0
		price_label.offset_right = 0
	super(_action_on_click)

	var artifact_id: String = _action_on_click.values.get("artifact_id", "")
	var artifact_data: ArtifactData = Global.get_artifact_data(artifact_id)
	if artifact_data != null:
		button.text = I18N.tr_data(artifact_data.object_id, "artifact_name", artifact_data.artifact_name)
		button.icon = FileLoader.load_texture(artifact_data.artifact_texture_path)
		var desc: String = I18N.tr_data(artifact_data.object_id, "artifact_description", artifact_data.artifact_description)
		description_label.text = "[center]" + desc + "[/center]"

func _style_shop_button() -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(0, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	button.clip_text = true
	button.expand_icon = true
	SlayMobileStyle.style_button(button, "dark", 18)
	if description_label != null:
		SlayMobileStyle.load_fonts()
		description_label.add_theme_font_override("normal_font", SlayMobileStyle.get_body_font())
		description_label.add_theme_font_size_override("normal_font_size", SlayMobileStyle.get_scaled_font_size(12))
		description_label.add_theme_color_override("default_color", Color(0.75, 0.75, 0.7))
