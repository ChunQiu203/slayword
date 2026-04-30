# UI element for a status effect
extends TextureRect
class_name StatusEffect

var status_effect_script: BaseStatusEffect

@onready var status_charge_label: Label = $StatusChargeLabel
@onready var status_secondary_charge_label = $StatusSecondaryChargeLabel

func update_status_charge_display() -> void:
	_update_status_texture()
	visible = status_effect_script.status_effect_data.status_effect_is_visible
	
	if status_effect_script.status_charges == 1 and not status_effect_script.status_effect_data.status_effect_stacks:
		status_charge_label.text = ""
	else:
		status_charge_label.text = str(status_effect_script.status_charges)
	
	if status_effect_script.status_secondary_charges == 0:
		status_secondary_charge_label.text = ""
	else:
		status_secondary_charge_label.text = str(status_effect_script.status_secondary_charges)
	
	
	tooltip_text = I18N.tr_data(status_effect_script.status_effect_data.object_id, "status_effect_name", status_effect_script.status_effect_data.status_effect_name)

func _update_status_texture() -> void:
	var status_effect_data: StatusEffectData = status_effect_script.status_effect_data
	var status_texture_path: String = status_effect_data.status_effect_texture_path
	if status_effect_script.status_charges < 0 and status_effect_data.status_effect_negative_charges_texture_path != "":
		status_texture_path = status_effect_data.status_effect_negative_charges_texture_path
	if status_texture_path != "":
		texture = FileLoader.load_texture(status_texture_path)
