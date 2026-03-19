extends Node3D

@export var mass:float = 1.0 #质量
@export var initial_velocity:Vector3 = Vector3.ZERO #初速度
@export var color:Color = Color.WHITE #颜色，用于区分
@export var is_star:bool = true
@export var velocity: Vector3
@export var Lifetime:float = 1000
@export var total_force:Vector3

@export var F:float
@export var V:float
@export var dis_center:float

@onready var timer = $"../Timer"
@onready var A = $"../A"
@onready var B = $"../B"
@onready var C = $"../C"
@onready var P = $"../planet"

var time_scale = 1 #时间尺度
var step:float
var total_dt:float
var vec = globals.rand_vec(10,-10,10,-10,10,-10).normalized()
var dead = false

func _ready():
	#添加计时器
	timer.autostart = true
	timer.one_shot = true
	timer.wait_time = 10**10
	timer.start()
	
	Engine.time_scale = 16
	
	add_to_group("Universe")
	#print(name,"已入组")
	
	#设置初始条件
	if name == "planet":
		mass = globals.P_mass
		global_position = globals.P_global_position
		initial_velocity = globals.P_initial_velocity
	elif name == "A":
		mass = globals.A_mass
		global_position = globals.A_global_position
		initial_velocity = globals.A_initial_velocity
	elif name == "B":
		mass = globals.B_mass
		global_position = globals.B_global_position
		initial_velocity = globals.B_initial_velocity
	elif name == "C":
		mass = globals.C_mass
		global_position = globals.C_global_position
		initial_velocity = globals.C_initial_velocity
		
	velocity = initial_velocity
	#print(name,":位置",global_position)
	
	#设置X3D的颜色，X可为A/B/C
	var MeshInstance = get_node_or_null("MeshInstance3D")
	if MeshInstance and MeshInstance.mesh is SphereMesh:
		var material = StandardMaterial3D.new() #建立新材质，方便缓存
		material.albedo_color = color #设置新材质颜色
		material.emission_enabled = is_star #开启自发光
		material.emission = color
		material.emission_energy_multiplier = 10000000
		#print(material.albedo_color)
		#print(material.emission)
		MeshInstance.material_override = material #覆盖原有材质，”强制换装“
		#print(name,"设置材质")
	
	#设置尾迹长度
	var GPUParticles = get_node_or_null("GPUParticles3D")
	if GPUParticles:
		GPUParticles.lifetime = 1000
		GPUParticles.trail_lifetime = 1000
		GPUParticles.amount = 100000
		#print(GPUParticles.trail_lifetime)
	
	var light = get_node_or_null("light")
	if light:
		light.light_energy = 100
		light.omni_range = 100

func _physics_process(delta: float):
	#快速计算模型
	step = 0.003
	total_dt = delta * time_scale
	var remaining = total_dt
	
	while remaining > 0:
		var current_step = min(step, remaining)
		_physics_update(current_step)
		remaining -= current_step
	
func _deferred_reload():
	if get_tree():
		get_tree().reload_current_scene()

func _physics_update(dt:float):
	#读取所有天体，强制所有力清零
	var all_bodies = get_tree().get_nodes_in_group("Universe")
	total_force = Vector3.ZERO
	
	#计算合力
	for body in all_bodies:
		
		if body == self:
			continue
		
		#引力的方向
		var forward = globals.force_forward_calculation(body.global_position,global_position)
		#分开计算引力
		var force = globals.Gravity_calculation(mass,body.mass,forward)
		#引力合力
		total_force += force
		
		is_end(self,body,all_bodies)
	
	#赋予初速度 v= （F合 * r/m） ** 0.5
	if self.initial_velocity == Vector3.ZERO:
		#判断是不是太近
		for body in all_bodies:
			if body == self:
				continue 
			#场景重开
			var dis = (body.global_position - global_position).length()
			#这里是距离范围，判定恒星之间不能太近也不能太远
			#当然也可以添加速度判断
			if dis < 170 or dis > 300:
				call_deferred("_deferred_reload")
				return
			if name == "planet":
				var maxd = 300
				var dis1 = (global_position - all_bodies[0].global_position).length()
				var dis2 = (global_position - all_bodies[1].global_position).length()
				var dis3 = (global_position - all_bodies[2].global_position).length()
				if dis1 > maxd and dis2 > maxd and dis3 > maxd:
					call_deferred("_deferred_reload")
					return
		#计算质心
		globals.center = globals.center_pos(all_bodies)
	
	
	#更新速度
	velocity = globals.velocity_update(total_force,mass,dt,velocity)
	F = total_force.length()
	V = velocity.length()
	#速度限制
	#dis_center = (global_position - globals.center).length()
	#if name == "planet":
		#if velocity.length() >20:
			#velocity = velocity.normalized() * 20
		#if dis_center > 400:
			#total_force += total_force.normalized() * (dis_center ** 0.2)
			#velocity = globals.velocity_update(total_force,mass,delta * time_scale,velocity)
	#elif name != "planet" and velocity.length() > 25:
		#velocity = velocity.normalized() * 25
	
	#更新位置
	global_position += velocity * dt
	#print(name,"已经更新位置",global_position)
	#print(name, " 速度: ", velocity.length())

#判断结束条件
func is_end(bodyA:Node3D,bodyB:Node3D,all_bodies:Array):
	var elapsed_time = timer.wait_time - timer.time_left
		#结束判断
	if dead == true:
		call_deferred("_change_scene")
	if globals.collision_end(all_bodies):
		dead = true
		print(name,"撞了")
		print("存活时间",elapsed_time)
		save_good_one(elapsed_time)
	if name == "planet":
		if globals.three_flying_stars(bodyA,all_bodies):
			dead = true
			print("三颗飞星")
			print("存活时间",elapsed_time)
			save_good_one(elapsed_time)
		if globals.too_far(bodyA,all_bodies):
			dead = true
			print("冷死了")
			print("存活时间",elapsed_time)
			save_good_one(elapsed_time)

func save_good_one(time:float):
	if time > 1800:
		var data = {
		"A": {"mass": globals.A_mass, "pos": globals.A_global_position, "vel": globals.A_initial_velocity},
		"B": {"mass": globals.B_mass, "pos": globals.B_global_position, "vel": globals.B_initial_velocity},
		"C": {"mass": globals.C_mass, "pos": globals.C_global_position, "vel": globals.C_initial_velocity},
		"P": {"mass": globals.P_mass, "pos": globals.P_global_position, "vel": globals.P_initial_velocity}
		}
		
		var file_path = "user://body.bin"
		var all_groups = []
		
		if FileAccess.file_exists(file_path):
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				all_groups = file.get_var()
				file.close()
		
		# 追加新组
		all_groups.append(data)
		
		# 写回文件
		var file_write = FileAccess.open(file_path, FileAccess.WRITE)
		file_write.store_var(all_groups)
		file_write.close()
		print("已保存第 ", all_groups.size(), " 组数据")
		
		call_deferred("_change_scene")

func _change_scene():
	if not is_inside_tree() or not get_tree():
		return
	get_tree().change_scene_to_file("res://scene/prediction_model.tscn")
