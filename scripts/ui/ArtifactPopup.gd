## Popup dialog showing artifact details when clicked.
extends Control

var artifact_data: ArtifactData

func _ready():
	# Make this control fill the entire viewport
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Full screen click catcher (close popup when clicking outside)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.gui_input.connect(_on_bg_input)
	add_child(bg)

	# Center panel
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(320, 280)
	panel.offset_left = -160
	panel.offset_right = 160
	panel.offset_top = -140
	panel.offset_bottom = 140
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.14, 0.22, 0.95)
	panel_style.border_color = Color(0.4, 0.5, 0.8)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# Main vertical layout
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Close button (top right of popup, not inside panel)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -36
	close_btn.offset_right = -8
	close_btn.offset_top = 8
	close_btn.offset_bottom = 36
	close_btn.pressed.connect(_close)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.8, 0.2, 0.2, 0.8)
	close_style.corner_radius_top_left = 4
	close_style.corner_radius_top_right = 4
	close_style.corner_radius_bottom_left = 4
	close_style.corner_radius_bottom_right = 4
	close_btn.add_theme_stylebox_override("normal", close_style)
	add_child(close_btn)

	# Artifact icon (larger)
	var icon_tex := TextureRect.new()
	icon_tex.texture = FileLoader.load_texture(artifact_data.artifact_texture_path)
	icon_tex.custom_minimum_size = Vector2(80, 80)
	icon_tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vbox.add_child(icon_tex)

	# Artifact name
	var name_label := Label.new()
	name_label.text = I18N.tr_data(artifact_data.object_id, "artifact_name", artifact_data.artifact_name)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Rarity label
	if len(artifact_data.ARTIFACT_RARITIES.keys()) > artifact_data.artifact_rarity:
		var rarity_label := Label.new()
		rarity_label.text = I18N.tr_enum("artifact_rarity", artifact_data.ARTIFACT_RARITIES.keys()[artifact_data.artifact_rarity])
		rarity_label.add_theme_font_size_override("font_size", 14)
		rarity_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
		rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(rarity_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Description
	var desc_label := Label.new()
	desc_label.text = I18N.tr_data(artifact_data.object_id, "artifact_description", artifact_data.artifact_description)
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Fade in animation
	modulate = Color(1, 1, 1, 0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 1), 0.2)

func _on_bg_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_close()

func _close() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.15)
	tw.tween_callback(queue_free)
