extends Node3D

@onready var follow_cam = $"../Player/CharacterBody3D/Camera3D"
@onready var map_cam = $"../Mapcamera"

var map_view = false

func _ready():
	follow_cam.current = true
	map_cam.current = false

func _input(event):
	if event.is_action_pressed("toggle_map"):
		change_camera()

func change_camera():
	map_view = !map_view
	
	if map_view:
		# 切换到大地图视角
		follow_cam.current = false
		map_cam.current = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		# 切换到角色视角
		follow_cam.current = true
		map_cam.current = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
