extends Camera3D

@export var target_group:String = "Universe"
@export var distance:float = 1000 #到中心距离
@export var rotation_speed:float = 0.0005 #旋转速度
@export var zoom_speed:float = 10 #滚轮缩放速度
@export var auto_rotation:bool = false #自动环绕

@export var default_distance: float = 31000
@export var default_yaw: float = 0.0
@export var default_pitch: float = 30.0

@export var min_v_angle:float = -89.0
@export var max_v_angle:float = 89.0

@onready var P = $"../Body/Planet2"
@onready var player = $"../Player/CharacterBody3D"

var center:Vector3
var angle:float=0.0
var yaw: float = 0.0       # 水平旋转角度（弧度）
var pitch: float = 0.0      # 垂直旋转角度（弧度）
var dragging: bool = false
var last_mouse_pos: Vector2

func _ready():
	global_position = Vector3(31000,0,0)
	# 设置初始角度（可选）
	yaw = 0.0
	pitch = 30.0  # 初始俯仰角，单位度

func _process(delta):
	_update_camera_position()

func reset_view():
	pass

func _update_camera_position():
	var rad_yaw = deg_to_rad(yaw)
	var rad_pitch = deg_to_rad(pitch)
	var offset = Vector3(
		cos(rad_yaw) * cos(rad_pitch),
		sin(rad_pitch),
		sin(rad_yaw) * cos(rad_pitch)
	) * distance
	var center = player.global_position  # 星球中心
	global_position = center + offset
	look_at(center, Vector3.UP)

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
