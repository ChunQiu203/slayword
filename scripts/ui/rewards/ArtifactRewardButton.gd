extends BaseRewardButton

func init(_action_on_click: BaseAction, _reward_group: int) -> void:
	super(_action_on_click, _reward_group)
	
	var artifact_id: String = _action_on_click.values.get("artifact_id", "")
	var artifact_data: ArtifactData = Global.get_artifact_data(artifact_id)
	if artifact_data != null:
		text = I18N.tr_data(artifact_data.object_id, "artifact_name", artifact_data.artifact_name)
		icon = FileLoader.load_texture(artifact_data.artifact_texture_path)
		tooltip_text = I18N.tr_data(artifact_data.object_id, "artifact_description", artifact_data.artifact_description)
