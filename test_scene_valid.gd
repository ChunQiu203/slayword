extends Node

func _ready():
	print("正在验证场景文件...")
	# 尝试加载场景来检查是否有错误
	var scene = load("res://scenes/Root.tscn")
	if scene:
		print("✅ Root.tscn 可以正常加载")
	else:
		print("❌ Root.tscn 加载失败")

	# 检查脚本
	var script = load("res://scripts/ui/RunSummaryOverlay.gd")
	if script:
		print("✅ RunSummaryOverlay.gd 可以正常加载")
	else:
		print("❌ RunSummaryOverlay.gd 加载失败")

	print("验证完成！")