extends BaseShopButton

@onready var button: Button = $Button

func _ready():
	button.button_up.connect(_on_button_up)
	_style_shop_button()

func init(_action_on_click: BaseAction) -> void:
	custom_minimum_size = Vector2(260, 82)
	_style_shop_button()
	super(_action_on_click)
	
	var consumable_object_id: String = _action_on_click.values.get("consumable_object_id", "")
	var consumable_data: ConsumableData = Global.get_consumable_data(consumable_object_id)
	if consumable_data != null:
		button.text = I18N.tr_data(consumable_data.object_id, "consumable_name", consumable_data.consumable_name)
		button.icon = FileLoader.load_texture(consumable_data.consumable_texture_path)


func _style_shop_button() -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(260, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	button.clip_text = true
	button.expand_icon = true
	SlayMobileStyle.style_button(button, "dark", 16)
