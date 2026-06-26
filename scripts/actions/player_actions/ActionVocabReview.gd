extends BaseAsyncAction

func perform_action():
	var vocab_study: VocabStudy = Global.get_node_or_null("/root/VocabStudy")
	if vocab_study == null:
		action_async_finished.emit()
		return

	var word: Dictionary = vocab_study._pick_word_for_prompt()
	if word.is_empty():
		Global.player_data.add_money(10)
		action_async_finished.emit()
		return

	var overlay: WordReviewOverlay = vocab_study._overlay
	if overlay == null:
		Global.player_data.add_money(10)
		action_async_finished.emit()
		return

	var old_parent: Node = overlay.get_parent()
	var scene_tree: SceneTree = Engine.get_main_loop() as SceneTree
	var root: Node = scene_tree.current_scene
	var run_screen: Node = root.get_node_or_null("RunScreen")
	if run_screen == null:
		for child in root.get_children():
			if child.name == "RunScreen":
				run_screen = child
				break
	if run_screen == null:
		Global.player_data.add_money(10)
		action_async_finished.emit()
		return

	old_parent.remove_child(overlay)
	run_screen.add_child(overlay)
	overlay.z_index = 200
	overlay.visible = true

	var outcome: int = await overlay.run_review(word)

	overlay.visible = false
	overlay.z_index = 80
	run_screen.remove_child(overlay)
	old_parent.add_child(overlay)

	match outcome:
		WordReviewOverlay.REVIEW_OUTCOME_OK:
			Global.player_data.add_money(get_action_value("money_amount", 30))
		WordReviewOverlay.REVIEW_OUTCOME_SKIPPED:
			Global.player_data.add_money(get_action_value("skip_money_amount", 10))
		WordReviewOverlay.REVIEW_OUTCOME_WRONG:
			pass

	action_async_finished.emit()
