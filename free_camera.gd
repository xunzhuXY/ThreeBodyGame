extends Camera3D

@export var target_group:String = "Universe"
@export var distance:float = 300 #到中心距离
@export var rotation_speed:float = 0.005 #旋转速度
@export var zoom_speed:float = 5.0 #滚轮缩放速度
@export var auto_rotation:bool = false #自动环绕

@export var min_v_angle:float = -89.0
@export var max_v_angle:float = 89.0



var center:Vector3
var angle:float=0.0
var yaw: float = 0.0       # 水平旋转角度（弧度）
var pitch: float = 0.0      # 垂直旋转角度（弧度）
var dragging: bool = false
var last_mouse_pos: Vector2

func _ready():
	# 设置初始角度（可选）
	yaw = 0.0
	pitch = 30.0  # 初始俯仰角，单位度

func _process(delta):
	#计算质心:(位置*质量)之和/总质量
	var bodies = get_tree().get_nodes_in_group("Universe")
	if bodies.is_empty():
		return
	
	var total_mass = 0.0
	var weighted_sum = Vector3.ZERO
	
	for body in bodies:
		var mass = body.mass
		total_mass += mass
		weighted_sum += body.global_position * mass
	
	#防止mass为零
	if total_mass > 0:
		center = weighted_sum / total_mass
	
	#设置摄像机位置以及朝向
	var rad_yaw = deg_to_rad(yaw)
	var rad_pitch = deg_to_rad(pitch)
	#下面是笛卡尔坐标
	var offset = Vector3(
		cos(rad_yaw) * cos(rad_pitch), #水平角度
		sin(rad_pitch), #垂直角度
		sin(rad_yaw) * cos(rad_pitch) #水平方向另一个角度
	) * distance
	
	global_position = center + offset
	
	look_at(center,Vector3.UP)
	
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				dragging = true
				last_mouse_pos = event.position
			else:
				dragging = false
		
		#滚轮处理
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance -= zoom_speed
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance += zoom_speed
		distance = clamp(distance, 0, 1000000)
	
	if dragging == true and event is InputEventMouseMotion:
		var delta = event.relative
		yaw -= delta.x * rotation_speed * 100 #速度适中 
		pitch -= delta.y * rotation_speed * 100
		
		#限制角度翻转
		pitch = clamp(pitch, min_v_angle, max_v_angle)
