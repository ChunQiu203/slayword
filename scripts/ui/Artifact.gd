## UI element for an artifact.
## Click to show artifact details popup.
extends TextureButton

var artifact_data: ArtifactData
var artifact_script: BaseArtifact

@onready var counter_label: Label = $CounterLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	Signals.artifact_proc.connect(_on_artifact_proc)
	Signals.artifact_counter_changed.connect(_on_artifact_counter_changed)
	# Allow left click (tap on mobile)
	button_mask = 1

func init(_artifact_data: ArtifactData):
	artifact_data = _artifact_data
	var artifact_script_asset: Resource = load(artifact_data.artifact_script_path)
	artifact_script = artifact_script_asset.new(artifact_data)
	texture_normal = FileLoader.load_texture(artifact_data.artifact_texture_path)
	update_artifact_counter()

	# Disable built-in tooltip
	tooltip_text = ""

	# Connect click
	pressed.connect(_on_pressed)

func _on_artifact_proc(_artifact_data: ArtifactData):
	if artifact_data == _artifact_data:
		animation_player.play("proc_anim")

func _on_artifact_counter_changed(_artifact_data: ArtifactData):
	if artifact_data == _artifact_data:
		update_artifact_counter()

func update_artifact_counter() -> void:
	if artifact_data != null:
		if artifact_data.artifact_counter == 0:
			counter_label.text = ""
		else:
			counter_label.text = str(artifact_data.artifact_counter)

func _on_pressed() -> void:
	# Don't show popup during action execution
	if ActionHandler.actions_being_performed:
		return

	# Instance popup
	var popup_script := load("res://scripts/ui/ArtifactPopup.gd")
	var popup: Control = popup_script.new()
	popup.artifact_data = artifact_data

	# Add to root viewport for correct centering
	var viewport := get_viewport()
	if viewport:
		viewport.add_child(popup)
		popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
