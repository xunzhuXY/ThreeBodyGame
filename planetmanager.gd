@tool
extends VoxelLodTerrain

func _ready():
	# 等待地形区块加载
	await get_tree().process_frame
	await get_tree().process_frame

	var mat = material
	if mat:
		# 设置固定范围
		mat.set_shader_parameter("min_height", 50.0)
		mat.set_shader_parameter("max_height", 52.0)

		# 编辑器下强制刷新材质，使预览生效
		if Engine.is_editor_hint():
			# 技巧：重新赋值材质触发刷新
			var old_mat = material
			material = null
			await get_tree().process_frame
			material = old_mat
			# 刷新视口
			var viewport = get_viewport()
			if viewport:
				viewport.update()
