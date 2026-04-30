# represents a consumable slot
# can be empty
extends TextureButton
class_name ConsumableButton

const EMPTY_CONSUMABLE_SLOT_TEXTURE_PATH: String = "external/sprites/consumables/consumable_empty_slot.svg"

var consumable_slot_index: int = 0	# which consumable slot this button corresponds to

signal consumable_slot_button_up(slot_index: int)

func _ready():
	button_up.connect(_on_button_up)

func init(_consumable_slot_index: int):
	consumable_slot_index = _consumable_slot_index
	
	var consumable_data: ConsumableData = Global.get_player_consumable_in_slot_index(consumable_slot_index)
	if consumable_data != null:
		self_modulate.a = 1.0
		texture_normal = FileLoader.load_texture(consumable_data.consumable_texture_path)
		# set tooltip
		tooltip_text = I18N.tr_data(consumable_data.object_id, "consumable_name", consumable_data.consumable_name)
		var consumable_description: String = I18N.tr_data(consumable_data.object_id, "consumable_description", consumable_data.consumable_description)
		if consumable_description != "":
			tooltip_text += "\n" + consumable_description
	else:
		# empty consumable slot
		texture_normal = FileLoader.load_texture(EMPTY_CONSUMABLE_SLOT_TEXTURE_PATH)
		self_modulate.a = 0.65
		tooltip_text = ""
	


func _on_button_up():
	consumable_slot_button_up.emit(consumable_slot_index)
