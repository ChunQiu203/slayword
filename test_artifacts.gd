extends Node
## Test script to validate artifact changes

func _ready():
	print("=== 遗物修改验证 ===\n")
	
	# 测试1: 检查新脚本文件是否存在
	print("1. 检查新遗物脚本文件:")
	var scripts = [
		"res://scripts/artifacts/ArtifactLensOfClarity.gd",
		"res://scripts/artifacts/ArtifactCometShard.gd",
		"res://scripts/artifacts/ArtifactOrreryOfWorlds.gd",
	]
	for script_path in scripts:
		var script = load(script_path)
		if script:
			print("  ✅ %s 可加载" % script_path.get_file())
		else:
			print("  ❌ %s 加载失败" % script_path.get_file())
	
	# 测试2: 检查JSON中的script_path是否正确
	print("\n2. 检查JSON配置:")
	var artifact_checks = {
		"artifact_lens_of_clarity": "ArtifactLensOfClarity",
		"artifact_comet_shard": "ArtifactCometShard",
		"artifact_orrery_of_worlds": "ArtifactOrreryOfWorlds",
	}
	for artifact_id in artifact_checks:
		var expected_script = artifact_checks[artifact_id]
		var json_path = "res://external/data/artifacts/%s.json" % artifact_id
		var file = FileAccess.open(json_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			if json_text.find(expected_script) != -1:
				print("  ✅ %s 引用正确脚本 %s" % [artifact_id, expected_script])
			else:
				print("  ❌ %s 未引用正确脚本" % artifact_id)
		else:
			print("  ❌ %s 无法读取" % artifact_id)
	
	# 测试3: 检查修复的遗物
	print("\n3. 检查修复的遗物:")
	var fix_checks = {
		"artifact_zodiac_codex": ["ActionAddEnergy", "ArtifactZodiacCodex"],
		"artifact_constellation_globe": ["ActionPlaceStar", "ArtifactConstellationGlobe"],
		"artifact_telescope_of_fate": ["star_house\": -1", "Scry"],
		"artifact_dark_star": ["status_effect_negate_damage", "ArtifactDarkStar"],
	}
	for artifact_id in fix_checks:
		var json_path = "res://external/data/artifacts/%s.json" % artifact_id
		var file = FileAccess.open(json_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			file.close()
			var all_found = true
			for check in fix_checks[artifact_id]:
				if json_text.find(check) == -1:
					all_found = false
					break
			if all_found:
				print("  ✅ %s 修复正确" % artifact_id)
			else:
				print("  ⚠️  %s 需要检查" % artifact_id)
		else:
			print("  ❌ %s 无法读取" % artifact_id)
	
	# 测试4: 检查Brass Astrolabe的反转旋转逻辑
	print("\n4. 检查Brass Astrolabe脚本:")
	var astrolabe_script = load("res://scripts/artifacts/ArtifactBrassAstrolabe.gd")
	if astrolabe_script:
		var script_text = FileAccess.open("res://scripts/artifacts/ArtifactBrassAstrolabe.gd", FileAccess.READ).get_as_text()
		if script_text.find("heliocentric_model") != -1:
			print("  ✅ 包含反转旋转逻辑")
		else:
			print("  ❌ 缺少反转旋转逻辑")
		if script_text.find("_rotate_stars_counter_clockwise") != -1:
			print("  ✅ 包含逆时针旋转函数")
		else:
			print("  ❌ 缺少逆时针旋转函数")
	
	print("\n=== 验证完成 ===")
	get_tree().quit()
