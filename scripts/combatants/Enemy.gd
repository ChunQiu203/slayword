extends BaseCombatant
class_name Enemy

@onready var enemy_intent: Control = $Visible/Intent
@onready var enemy_intent_texture: TextureRect = $Visible/Intent/IntentTexture
@onready var enemy_intent_amount_text: Label = $Visible/Intent/IntentAmount

@onready var name_label = $Visible/Sprite/NameLabel

const INTENT_TYPE_ATTACK: String = "attack"
const INTENT_TYPE_BLOCK: String = "block"
const INTENT_TYPE_BUFF: String = "buff"
const INTENT_TYPE_DEBUFF: String = "debuff"
const INTENT_TYPE_SUMMON: String = "summon"
const INTENT_TYPE_SPECIAL: String = "special"
const INTENT_TYPE_NONE: String = "none"

const INTENT_TEXTURE_ATTACK: String = "external/sprites/intents/intent_attack.svg"
const INTENT_TEXTURE_BLOCK: String = "external/sprites/intents/intent_block.svg"
const INTENT_TEXTURE_BUFF: String = "external/sprites/intents/intent_buff.svg"
const INTENT_TEXTURE_DEBUFF: String = "external/sprites/intents/intent_debuff.svg"
const INTENT_TEXTURE_SUMMON: String = "external/sprites/intents/intent_summon.svg"
const INTENT_TEXTURE_SPECIAL: String = "external/sprites/intents/intent_special.svg"

const INTENT_TEXTURE_BY_TYPE: Dictionary[String, String] = {
	INTENT_TYPE_ATTACK: INTENT_TEXTURE_ATTACK,
	INTENT_TYPE_BLOCK: INTENT_TEXTURE_BLOCK,
	INTENT_TYPE_BUFF: INTENT_TEXTURE_BUFF,
	INTENT_TYPE_DEBUFF: INTENT_TEXTURE_DEBUFF,
	INTENT_TYPE_SUMMON: INTENT_TEXTURE_SUMMON,
	INTENT_TYPE_SPECIAL: INTENT_TEXTURE_SPECIAL,
}

var enemy_data: EnemyData
var enemy_slot: int = 0 # the spawn slot the enemy is in

var enemy_intent_attack_damage: int = 0
var enemy_intent_number_of_attacks: int = 0
var enemy_intent_block_amount: int = 0

func init(_enemy_data: EnemyData):
	enemy_data = _enemy_data
	
	selection_button.mouse_entered.connect(_on_mouse_entered)
	selection_button.mouse_exited.connect(_on_mouse_exited)
	
	sprite.texture = FileLoader.load_texture(enemy_data.enemy_texture_path)
	
	# apply initial effects
	for status_effect_object_id in enemy_data.enemy_initial_status_effects.keys():
		var charge_amount: int = enemy_data.enemy_initial_status_effects[status_effect_object_id]
		add_status_effect_charges(status_effect_object_id, charge_amount)
	
	name_label.text = I18N.tr_data(enemy_data.object_id, "enemy_name", enemy_data.enemy_name)
	
	# update_health_bar()
	layered_health_bar.init(enemy_data.enemy_health, enemy_data.enemy_health_max)

## Does damage to combatant and returns [unblocked damage dealt, damage to 0 (if enemy dies), overkill damage (if enemy dies)]
## eg 15 damage on 10 remaining health and 3 block will return [12, 10, 2].
## bypass_block = true will do damage directly to health.
func damage(_damage: int, bypass_block: bool = false) -> Array[int]:
	var bypassed_damage: int = _damage # raw unblocked damage
	var bypassed_damage_capped: int = 0 # damage done that does not factor in overkill damage
	var overkill_damage: int = 0 # damage done past 0

	if enemy_data.enemy_block > 0 and not bypass_block:
		if enemy_data.enemy_block > _damage:
			# damage less than block
			enemy_data.enemy_block -= _damage
			bypassed_damage = 0
			create_block_text()
			Signals.combatant_blocked.emit(self, _damage)
		else:
			# damage exceeds block
			bypassed_damage = _damage - enemy_data.enemy_block
			enemy_data.enemy_block = 0
			Signals.combatant_block_broken.emit(self)
	
	block.visible = enemy_data.enemy_block > 0
	block_amount.text = str(enemy_data.enemy_block)
	
	if bypassed_damage <= 0:
		return [0,0,0]
	
	create_damage_text(bypassed_damage)
	
	overkill_damage = max(0, bypassed_damage - enemy_data.enemy_health)
	bypassed_damage_capped = bypassed_damage - overkill_damage
	
	if enemy_data.enemy_health > 0:
		enemy_data.enemy_health = max(0, enemy_data.enemy_health - bypassed_damage)
		Signals.combatant_damaged.emit(self, bypassed_damage)
		update_health_bar(true)
		if enemy_data.enemy_health <= 0:
			if not animation_player.is_playing():
				animation_player.play("death")
				remove_from_group("enemies")
				Signals.enemy_killed.emit(self)
	
	return [bypassed_damage, bypassed_damage_capped, overkill_damage]

func set_block(amount: int) -> void:
	enemy_data.enemy_block = amount
	enemy_data.enemy_block = max(0, enemy_data.enemy_block)
	
	block.visible = enemy_data.enemy_block > 0
	block_amount.text = str(enemy_data.enemy_block)

func get_block() -> int:
	return enemy_data.enemy_block

func add_block(amount: int) -> void:
	set_block(enemy_data.enemy_block + amount)
	if amount > 0:
		Signals.combatant_block_added.emit(self)

func update_health_bar(as_damage: bool = false) -> void:
	if as_damage:
		layered_health_bar.apply_damage(enemy_data.enemy_health, enemy_data.enemy_health_max, status_id_to_status_effects)
	else:
		layered_health_bar.update_health_layers(enemy_data.enemy_health, enemy_data.enemy_health_max, status_id_to_status_effects)

func cycle_enemy_intent():
	enemy_data.cycle_next_attack_state()
	update_enemy_intent()
	Signals.enemy_intent_changed.emit()

func update_enemy_intent():
	# displays the enemy's current action plan
	var attack_damages: Array = enemy_data.get_current_attack_damages()
	var attack_damage: int = attack_damages[0]
	var number_of_attacks: int = attack_damages[1]
	var player: Player = Global.get_player()

	enemy_intent_attack_damage = 0
	enemy_intent_number_of_attacks = 0
	enemy_intent_block_amount = 0

	var action_data: Array[Dictionary] = [{
			Scripts.ACTION_ATTACK:
				{
				"damage": attack_damage,
				"target_override": BaseAction.TARGET_OVERRIDES.PLAYER
				}}]
	var generated_action: BaseAction = ActionGenerator.create_actions(self, null, [player], action_data, null)[0]
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = generated_action._intercept_action([player], true)

	if len(action_interceptor_processors) == 1:
		var action_interceptor_processor: ActionInterceptorProcessor = action_interceptor_processors[0]
		enemy_intent_attack_damage = max(0, action_interceptor_processor.get_shadowed_action_values("damage", 0))

	action_data = [{
		Scripts.ACTION_ATTACK_GENERATOR:
			{
			"damage": attack_damage,
			"number_of_attacks": number_of_attacks,
			"target_override": BaseAction.TARGET_OVERRIDES.PLAYER
			}}]
	generated_action = ActionGenerator.create_actions(self, null, [player], action_data, null)[0]
	action_interceptor_processors = generated_action._intercept_action([player], true)

	if len(action_interceptor_processors) == 1:
		var action_interceptor_processor: ActionInterceptorProcessor = action_interceptor_processors[0]
		enemy_intent_number_of_attacks = max(0, action_interceptor_processor.get_shadowed_action_values("number_of_attacks", 0))

	var block_amount: int = enemy_data.get_current_attack_block()
	if block_amount > 0:
		action_data = [{
			Scripts.ACTION_BLOCK:
				{
				"block": block_amount,
				"target_override": BaseAction.TARGET_OVERRIDES.PARENT
				}}]
		generated_action = ActionGenerator.create_actions(self, null, [self], action_data, null)[0]
		action_interceptor_processors = generated_action._intercept_action([self], true)

		if len(action_interceptor_processors) == 1:
			var action_interceptor_processor: ActionInterceptorProcessor = action_interceptor_processors[0]
			enemy_intent_block_amount = max(0, action_interceptor_processor.get_shadowed_action_values("block", 0))

	var custom_summary: Dictionary = _summarize_custom_intents(enemy_data.get_current_attack_custom_actions())
	var intent_type: String = _get_primary_intent_type(custom_summary)
	enemy_intent.visible = intent_type != INTENT_TYPE_NONE
	if not enemy_intent.visible:
		return

	_apply_intent_style(intent_type)
	enemy_intent_texture.texture = FileLoader.load_texture(INTENT_TEXTURE_BY_TYPE.get(intent_type, INTENT_TEXTURE_SPECIAL))
	var amount_text: String = _get_intent_amount_text(intent_type, custom_summary)
	enemy_intent_amount_text.text = amount_text
	enemy_intent_amount_text.visible = amount_text != ""
	_position_intent_icon(amount_text != "")

func _summarize_custom_intents(custom_actions: Array[Dictionary]) -> Dictionary:
	var summary: Dictionary = {
		"buffs": [],
		"debuffs": [],
		"summons": 0,
		"specials": 0,
	}

	for custom_action: Dictionary in custom_actions:
		for action_script_path_raw in custom_action.keys():
			var action_script_path: String = str(action_script_path_raw)
			var action_values: Dictionary = {}
			if custom_action[action_script_path_raw] is Dictionary:
				action_values = custom_action[action_script_path_raw]

			match action_script_path:
				Scripts.ACTION_APPLY_STATUS:
					_collect_status_intent(summary, action_values)
				Scripts.ACTION_SUMMON_ENEMIES:
					summary["summons"] = int(summary["summons"]) + int(action_values.get("number_of_spawns", 1))
				Scripts.ACTION_BLOCK:
					if _intent_targets_parent(action_values):
						enemy_intent_block_amount += int(action_values.get("block", 0))
					else:
						summary["specials"] = int(summary["specials"]) + 1
				Scripts.ACTION_DIRECT_DAMAGE, Scripts.ACTION_ATTACK, Scripts.ACTION_ATTACK_GENERATOR:
					summary["specials"] = int(summary["specials"]) + 1
				_:
					summary["specials"] = int(summary["specials"]) + 1

	return summary

func _collect_status_intent(summary: Dictionary, action_values: Dictionary) -> void:
	var status_effect_object_id: String = str(action_values.get("status_effect_object_id", ""))
	if status_effect_object_id == "":
		summary["specials"] = int(summary["specials"]) + 1
		return

	var status_effect_data: StatusEffectData = Global.get_status_effect_data(status_effect_object_id)
	if status_effect_data == null:
		summary["specials"] = int(summary["specials"]) + 1
		return

	var charge_amount: int = int(action_values.get("status_charge_amount", action_values.get("status_effect_charges", 1)))
	var status_label: String = I18N.tr_data(status_effect_data.object_id, "status_effect_name", status_effect_data.status_effect_name)
	if charge_amount != 0:
		status_label += " " + str(abs(charge_amount))

	if status_effect_data.status_effect_type == StatusEffectData.STATUS_EFFECT_TYPES.DEBUFF and _intent_targets_player(action_values):
		summary["debuffs"].append(status_label)
	elif status_effect_data.status_effect_type == StatusEffectData.STATUS_EFFECT_TYPES.BUFF and _intent_targets_parent(action_values):
		summary["buffs"].append(status_label)
	else:
		summary["specials"] = int(summary["specials"]) + 1

func _intent_targets_player(action_values: Dictionary) -> bool:
	var target_override: int = int(action_values.get("target_override", BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS))
	return [
		BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS,
		BaseAction.TARGET_OVERRIDES.PLAYER,
		BaseAction.TARGET_OVERRIDES.ALL_COMBATANTS,
	].has(target_override)

func _intent_targets_parent(action_values: Dictionary) -> bool:
	var target_override: int = int(action_values.get("target_override", BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS))
	return [
		BaseAction.TARGET_OVERRIDES.PARENT,
		BaseAction.TARGET_OVERRIDES.ALL_COMBATANTS,
	].has(target_override)

func _get_primary_intent_type(custom_summary: Dictionary) -> String:
	if enemy_intent_attack_damage * enemy_intent_number_of_attacks > 0:
		return INTENT_TYPE_ATTACK
	if enemy_intent_block_amount > 0:
		return INTENT_TYPE_BLOCK
	if int(custom_summary.get("summons", 0)) > 0:
		return INTENT_TYPE_SUMMON
	if len(custom_summary.get("debuffs", [])) > 0:
		return INTENT_TYPE_DEBUFF
	if len(custom_summary.get("buffs", [])) > 0:
		return INTENT_TYPE_BUFF
	if int(custom_summary.get("specials", 0)) > 0:
		return INTENT_TYPE_SPECIAL
	return INTENT_TYPE_NONE

func _get_intent_amount_text(intent_type: String, custom_summary: Dictionary) -> String:
	match intent_type:
		INTENT_TYPE_ATTACK:
			if enemy_intent_number_of_attacks > 1:
				return str(enemy_intent_attack_damage) + "x" + str(enemy_intent_number_of_attacks)
			return str(enemy_intent_attack_damage)
		INTENT_TYPE_BLOCK:
			return "+" + str(enemy_intent_block_amount)
		INTENT_TYPE_SUMMON:
			var summon_count: int = int(custom_summary.get("summons", 1))
			if summon_count > 1:
				return "x" + str(summon_count)
			return ""
		INTENT_TYPE_DEBUFF:
			return ""
		INTENT_TYPE_BUFF:
			return ""
		INTENT_TYPE_SPECIAL:
			return "?"
	return ""

func _apply_intent_style(intent_type: String) -> void:
	enemy_intent_amount_text.add_theme_color_override("font_color", Color.WHITE)
	enemy_intent_texture.modulate = _get_intent_color(intent_type)

func _position_intent_icon(has_amount: bool) -> void:
	if has_amount:
		enemy_intent_texture.offset_left = 40.0
		enemy_intent_texture.offset_right = 76.0
	else:
		enemy_intent_texture.offset_left = 24.0
		enemy_intent_texture.offset_right = 60.0

func _get_intent_color(intent_type: String) -> Color:
	match intent_type:
		INTENT_TYPE_ATTACK:
			return Color(1.0, 0.32, 0.22, 1.0)
		INTENT_TYPE_BLOCK:
			return Color(0.36, 0.78, 1.0, 1.0)
		INTENT_TYPE_BUFF:
			return Color(0.34, 0.90, 0.54, 1.0)
		INTENT_TYPE_DEBUFF:
			return Color(0.72, 0.44, 1.0, 1.0)
		INTENT_TYPE_SUMMON:
			return Color(1.0, 0.73, 0.26, 1.0)
		_:
			return Color(0.72, 0.77, 0.84, 1.0)

func is_alive() -> bool:
	return enemy_data.enemy_health > 0

func is_attacking() -> bool:
	return enemy_intent_attack_damage * enemy_intent_number_of_attacks > 0

func _on_combat_started(_event_id: String):
	pass

func _on_combat_ended():
	queue_free()

func _on_player_turn_started():
	cycle_enemy_intent()

func _on_selection_button_up():
	if is_alive():
		Signals.enemy_clicked.emit(self)

func _on_mouse_entered():
	Signals.enemy_hovered.emit(self)
	name_label.visible = true

func _on_mouse_exited():
	Signals.enemy_hovered.emit(null)
	name_label.visible = false

func _on_death_animtation_finished():
	# called from animation player
	Signals.enemy_death_animation_finished.emit(self)
