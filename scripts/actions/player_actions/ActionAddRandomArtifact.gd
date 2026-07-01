extends BaseAction

func perform_action():
	var artifact_count: int = get_action_value("artifact_count", 1)
	var artifact_rarities: Array = get_action_value("artifact_rarities", ArtifactData.STANDARD_ARTIFACT_RARITIES)
	
	var artifact_ids: Array[String] = Global.player_data.get_next_artifacts_from_pool(artifact_count, artifact_rarities, false, false, true)
	for artifact_id: String in artifact_ids:
		Global.player_data.add_artifact(artifact_id)

func _to_string():
	return "Add Random Artifact Action"
