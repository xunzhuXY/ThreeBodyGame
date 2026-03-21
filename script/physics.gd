extends CharacterBody3D

@export var g = 0.98

var planet: StaticBody3D

func _ready():
	#寻找路径以计算相对位置
	planet = get_node("../../Body/Planet") 

func _physics_process(delta: float) -> void:
	#1. 重力方向
	var down = (planet.global_position - global_position).normalized()
	var up = -down
	#更新物理引擎的向上方向，让 is_on_floor() 正确工作
	up_direction = up
	
	global_transform.basis = Basis.looking_at(up)
	
	#2. 应用重力
	velocity += down * g * delta
	
	move_and_slide()
