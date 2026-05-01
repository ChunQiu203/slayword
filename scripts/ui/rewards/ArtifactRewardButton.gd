extends BaseRewardButton

func init(_action_on_click: BaseAction, _reward_group: int) -> void:
	super(_action_on_click, _reward_group)
	refresh_localized_text()

func refresh_localized_text() -> void:
	var artifact_id: String = action_on_click.values.get("artifact_id", "")
	var artifact_data: ArtifactData = Global.get_artifact_data(artifact_id)
	if artifact_data != null:
		var artifact_name := I18N.tr_data(artifact_data.object_id, "artifact_name", artifact_data.artifact_name)
		var artifact_description := I18N.tr_data(artifact_data.object_id, "artifact_description", artifact_data.artifact_description)
		text = artifact_name
		icon = FileLoader.load_texture(artifact_data.artifact_texture_path)
		tooltip_text = "%s\n%s" % [artifact_name, artifact_description]
