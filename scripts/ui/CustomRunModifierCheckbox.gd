extends CheckBox
class_name CustomRunModifierCheckbox

var run_modifier_object_id: String = ""	# the character id this button represents

func init(_run_modifier_object_id: String) -> void:
	run_modifier_object_id = _run_modifier_object_id
	refresh_localized_text()

func refresh_localized_text() -> void:
	var run_modifier_data: RunModifierData = Global.get_run_modifier_data(run_modifier_object_id)
	if run_modifier_data != null:
		text = I18N.tr_data(run_modifier_data.object_id, "run_modifier_name", run_modifier_data.run_modifier_name)
		tooltip_text = I18N.tr_data(run_modifier_data.object_id, "run_modifier_description", run_modifier_data.run_modifier_description)
