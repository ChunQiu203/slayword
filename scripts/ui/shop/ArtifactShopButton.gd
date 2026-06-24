extends BaseShopButton

@onready var button: Button = $Button

func _ready():
	button.button_up.connect(_on_button_up)
	_style_shop_button()

func init(_action_on_click: BaseAction) -> void:
	custom_minimum_size = Vector2(260, 82)
	_style_shop_button()
	# Reposition price label below the button
	if price_label != null:
		price_label.offset_top = 54
		price_label.offset_bottom = 80
		price_label.offset_left = 0
		price_label.offset_right = 260
	super(_action_on_click)
	
	var artifact_id: String = _action_on_click.values.get("artifact_id", "")
	var artifact_data: ArtifactData = Global.get_artifact_data(artifact_id)
	if artifact_data != null:
		button.text = I18N.tr_data(artifact_data.object_id, "artifact_name", artifact_data.artifact_name)
		button.icon = FileLoader.load_texture(artifact_data.artifact_texture_path)


func _style_shop_button() -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(260, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	button.clip_text = true
	button.expand_icon = true
	SlayMobileStyle.style_button(button, "dark", 16)
