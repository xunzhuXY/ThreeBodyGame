@tool
extends VoxelLodTerrain

func _ready():
	# 获取当前已分配的生成器（保留编辑器中的配置）
	var generator = get_generator()
	if generator and generator is VoxelGeneratorScript:
		# 设置随机种子
		generator.seed = randi()
		# 可选：强制刷新地形（可能需要重新生成网格）
		# 有些版本会自动刷新，不需要手动调用
		print("地形生成器种子已更新为: ", generator.seed)
	else:
		print("未找到生成器或类型不正确")
