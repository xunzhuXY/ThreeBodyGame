extends Node

func _ready():
	var file = FileAccess.open("user://body.bin", FileAccess.READ)
	if file:
		var data = file.get_var()  # 读取之前保存的数据
		print("读取到的数据: ", data)
		print("当前共有", data.size(), " 组")
		# 如果 data 是字典，可以进一步打印其内容
		if data is Dictionary:
			for key in data:
				print(key, ": ", data[key])
	else:
		print("文件打开失败，错误码: ", FileAccess.get_open_error())
