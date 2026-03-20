extends Node

func _ready():
	var src_path = "res://data/body.bin"   # 你放在项目里的原始文件
	var dst_path = "user://body.bin"       # 运行时实际使用的文件

	# 检查 user:// 下是否已存在该文件
	if not FileAccess.file_exists(dst_path):
		print("首次运行，正在复制初始数据文件...")
		# 从 res:// 读取
		var src_file = FileAccess.open(src_path, FileAccess.READ)
		if src_file:
			var data = src_file.get_var()
			src_file.close()

			# 写入到 user://
			var dst_file = FileAccess.open(dst_path, FileAccess.WRITE)
			if dst_file:
				dst_file.store_var(data)
				dst_file.close()
				print("数据文件复制成功！")
			else:
				printerr("无法写入 user://body.bin")
		else:
			printerr("无法读取初始数据文件：", src_path)
	else:
		print("数据文件已存在，直接使用。")
