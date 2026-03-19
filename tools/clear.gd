extends Node

func _ready():
	var file_path = "user://body.bin"
	if not FileAccess.file_exists(file_path):
		print("文件不存在")
		return

	# 读取现有数据
	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = file.get_var()
	file.close()

	if not (data is Array):
		print("文件格式错误，不是数组")
		return

	print("原始组数: ", data.size())

	# 去重（基于 JSON 字符串比较，确保完全相同的组被移除）
	var unique_data = []
	var seen = []
	for group in data:
		var json_str = JSON.stringify(group)
		if json_str not in seen:
			seen.append(json_str)
			unique_data.append(group)

	print("去重后组数: ", unique_data.size())

	# 写回文件
	var file_write = FileAccess.open(file_path, FileAccess.WRITE)
	file_write.store_var(unique_data)
	file_write.close()
	print("文件已更新")

	# 可选：退出游戏
	get_tree().quit()
