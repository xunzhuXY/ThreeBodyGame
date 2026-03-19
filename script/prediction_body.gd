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


func _ready():
	globals.dead = false
	#添加计时器
	timer.autostart = true
	timer.one_shot = true
	timer.wait_time = 10**10
	timer.start()
	#timer.timeout.connect(enough_time)
	Engine.time_scale = 1
	
	add_to_group("Universe")
	#print(name,"已入组")
	
	#随机生成，位置与速度还有质量
	initial_velocity = Vector3.ZERO
	if name == "planet":
		global_position = Vector3.ZERO
		#global_position = globals.rand_vec(0,0,0,0,0,0)
		#initial_velocity = globals.rand_vec(3,-5,5,-3,3,-5)
		self.mass = 5
	else:
		global_position = globals.rand_vec(400,0,400,0,150,-150)
		
		if name == "A":
			#2700 2700 2500
			self.mass = randf_range(3000,4000)
		elif name == "B":
			self.mass = randf_range(3000,4000)
		else:
			self.mass = randf_range(2900,3500)
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
		GPUParticles.trail_lifetime = 10000
		GPUParticles.amount = 10000
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

func _physics_update(dt:float):	
	#读取所有天体，强制所有力清零
	var all_bodies = get_tree().get_nodes_in_group("Universe")
	total_force = Vector3.ZERO
	
	#计算合力
	for body in all_bodies:
		
		if body == self:
			continue
		
		#减少对撞概率
		#var distance = (global_position - body.global_position).length()
		#var angle = initial_velocity.angle_to(body.initial_velocity)
		#var maxangle = 150
		#var currunt_speed = velocity.length()
		#var desired_dir = initial_velocity.cross(body.initial_velocity).normalized()
		#if distance <= 60:
			#if angle >= deg_to_rad(maxangle):
				#velocity += desired_dir * 4
				##velocity = velocity.normalized()* currunt_speed
		
		#引力的方向
		var forward = globals.force_forward_calculation(body.global_position,global_position)
		#分开计算引力
		var force = globals.Gravity_calculation(mass,body.mass,forward)
		#引力合力
		total_force += force
		#print(name,"当前合力为",total_force)
		
	is_end(self,all_bodies)
	
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
			if dis < 180 or dis > 400:
				call_deferred("_deferred_reload")
				return
		
		globals.center = globals.center_pos(all_bodies)
		var center = globals.center
		var body_radius = (center - global_position).length()
		var speed = (total_force.length() * body_radius / self.mass) ** 0.5
		initial_velocity = total_force.cross(vec).normalized() * speed * randf_range(0.8,1.0)
		velocity = initial_velocity
		
		#对行星单独设置
		if name == "planet":
			var n = randi_range(0,2) #随机挑选恒星
			var bd = all_bodies[n]
			var out = globals.rand_vec(35,20,35,20,35,20)
			body_radius = out.length()
			global_position = bd.global_position + out
			
			var maxd = 350
			var mind = 50
			var dis1 = (global_position - all_bodies[0].global_position).length()
			var dis2 = (global_position - all_bodies[1].global_position).length()
			var dis3 = (global_position - all_bodies[2].global_position).length()
			if dis1 > maxd and dis2 > maxd and dis3 > maxd:
				call_deferred("_deferred_reload")
				return
			if out.length() < mind :
				call_deferred("_deferred_reload")
				return
			
			speed = (total_force.length() * body_radius / self.mass) ** 0.5
			var forw = global_position - bd.global_position
			initial_velocity = forw.cross(bd.initial_velocity).normalized() * speed * randf_range(0.8,0.5)
		#print(name,"位置:",global_position,"\n初速度：",initial_velocity,"\n质量：",mass)
		
		#保存初始数据：
		if name == "planet":
			globals.P_mass = mass
			globals.P_global_position = global_position
			globals.P_initial_velocity = initial_velocity
		elif name == "A":
			globals.A_mass = mass
			globals.A_global_position = global_position
			globals.A_initial_velocity = initial_velocity
		elif name == "B":
			globals.B_mass = mass
			globals.B_global_position = global_position
			globals.B_initial_velocity = initial_velocity
		elif name == "C":
			globals.C_mass = mass
			globals.C_global_position = global_position
			globals.C_initial_velocity = initial_velocity
	
	#更新速度
	velocity = globals.velocity_update(total_force,mass,dt,velocity)
	F = total_force.length()
	V = velocity.length()
	#速度限制
	dis_center = (global_position - globals.center).length()
	#if name == "planet":
		#if velocity.length() >15:
			#velocity = velocity.normalized() * 15
		#if dis_center > 500:
			#total_force += total_force.normalized() * (dis_center - 500) / 50
			#velocity = globals.velocity_update(total_force,mass,dt * time_scale,velocity)
	#elif name != "planet" and velocity.length() > 25:
		#velocity = velocity.normalized() * 25
	
	#更新位置
	global_position += velocity * dt
	#print(name,"已经更新位置",global_position)
	#print(name, " 速度: ", velocity.length())

#判断结束条件
func is_end(bodyA:Node3D,all_bodies:Array):
	var elapsed_time = timer.wait_time - timer.time_left
		#结束判断
	if globals.dead == true:
		call_deferred("_deferred_reload")
	if globals.dead == false:
		if globals.collision_end(all_bodies):
			globals.dead = true
			print(name,"撞了")
			print("存活时间",elapsed_time)
			save_good_one(elapsed_time)
		if name == "planet":
			if globals.three_flying_stars(bodyA,all_bodies):
				globals.dead = true
				print("三颗飞星")
				print("存活时间",elapsed_time)
				save_good_one(elapsed_time)
			if globals.too_far(bodyA,all_bodies):
				globals.dead = true
				print("冷死了")
				print("存活时间",elapsed_time)
				elapsed_time -= 50 
				save_good_one(elapsed_time)

#func enough_time():
	#if not is_inside_tree():
		#return
	#print("成功预测")
	#call_deferred("_change_scene")

#func _change_scene():
	#if not is_inside_tree() or not get_tree():
		#return
	#get_tree().change_scene_to_file("res://scene/model.tscn")

func _deferred_reload():
	if not is_inside_tree() or not get_tree():
		return
	if get_tree():
		get_tree().reload_current_scene()

func save_good_one(time:float):
	if time > 450:
		var data = {
		"A": {"mass": globals.A_mass, "pos": globals.A_global_position, "vel": globals.A_initial_velocity},
		"B": {"mass": globals.B_mass, "pos": globals.B_global_position, "vel": globals.B_initial_velocity},
		"C": {"mass": globals.C_mass, "pos": globals.C_global_position, "vel": globals.C_initial_velocity},
		"P": {"mass": globals.P_mass, "pos": globals.P_global_position, "vel": globals.P_initial_velocity},
		"time": time
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
		call_deferred("_deferred_reload")
