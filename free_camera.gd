extends Camera3D

@export var move_speed:=10.0 #移动速度
@export var mouse_sensitivity:=0.002 #灵敏度

func _ready():
	#捕获鼠标，让鼠标消失来拖动视角
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	#鼠标移动旋转视角
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity) # 水平旋转
		rotate_x(-event.relative.y * mouse_sensitivity) # 垂直旋转
		#设置旋转范围，防止乱翻
		rotation.x = clamp(rotation.x, deg_to_rad(-90.0), deg_to_rad(90.0))
	
	#esc退出释放/捕获鼠标
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta):
	#获取wsad或者上下箭头
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# 计算移动向量：基于摄像机当前的朝向
	# 注意：Camera3D 的 forward 方向是 -Z 轴 [citation:3]
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 垂直移动 (Q/E 或 空格/Ctrl，需自行在输入映射中设置)
	if Input.is_action_pressed("ui_page_up"): # 示例：向上
		direction += Vector3.UP
	if Input.is_action_pressed("ui_page_down"): # 示例：向下
		direction += Vector3.DOWN
	if Input.is_action_pressed("space"): #归位
		global_position = Vector3(30.283,14.49,134.4)
	
	translate(direction * move_speed * delta)
	
	
	
