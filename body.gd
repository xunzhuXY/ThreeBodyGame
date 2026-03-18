extends Node3D

@export var mass:float = 1.0 #质量
@export var initial_velocity:Vector3 = Vector3.ZERO #初速度
@export var color:Color = Color.WHITE #颜色，用于区分
@export var is_star:bool = true
@export var velocity: Vector3
@export var Lifetime:float = 1000

@onready var timer = $"../Timer"

var time_scale = 0.5 #时间尺度
var vec = globals.rand_vec(10,-10,10,-10,10,-10).normalized()

func _ready():
	#添加计时器
	timer.autostart = true
	timer.wait_time = 1*(10**10)
	timer.start()
	
	add_to_group("Universe")
	#print(name,"已入组")
	
	#随机生成，位置与速度还有质量
	initial_velocity = Vector3.ZERO
	if name == "planet":
		global_position = Vector3.ZERO
		#global_position = globals.rand_vec(0,0,0,0,0,0)
		#initial_velocity = globals.rand_vec(3,-5,5,-3,3,-5)
		self.mass = 1
	else:
		global_position = globals.rand_vec(300,0,300,0,150,-150)
		
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
		GPUParticles.trail_lifetime = 1000
		GPUParticles.amount = 1000
		#print(GPUParticles.trail_lifetime)
	
	var light = get_node_or_null("light")
	if light:
		light.light_energy = 100
		light.omni_range = 100

func _physics_process(delta: float):
	
	#读取所有天体，强制所有力清零
	var all_bodies = get_tree().get_nodes_in_group("Universe")
	var total_force = Vector3.ZERO
	
	
	
	#计算合力
	for body in all_bodies:
		
		if body == self:
			continue
		
			
		var elapsed_time = timer.wait_time - timer.time_left
		#结束判断
		if globals.collision_end(self,body):
			print(name,"撞了")
			print("存活时间",elapsed_time)
			get_tree().quit()
		if name == "planet":
			if globals.three_flying_stars(self,all_bodies):
				print("三颗飞星")
				print("存活时间",elapsed_time)
				get_tree().quit()
			if globals.too_far(self,all_bodies):
				print("冷死了")
				print("存活时间",elapsed_time)
				get_tree().quit()
		
		
		#引力的方向
		var forward = globals.force_forward_calculation(body.global_position,global_position)
		#分开计算引力
		var force = globals.Gravity_calculation(mass,body.mass,forward)
		#引力合力
		total_force += force
		#print(name,"当前合力为",total_force)
	
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
			if dis < 150 or dis > 250:
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
		
		var center = globals.center_pos(all_bodies)
		var body_radius = (center - global_position).length()
		var speed = (total_force.length() * body_radius / self.mass) ** 0.5
		initial_velocity = total_force.cross(vec).normalized() * speed * 0.8
		velocity = initial_velocity
		
		if name == "planet":
			var n = randi_range(0,2) #随机挑选恒星
			var bd = all_bodies[n]
			global_position = bd.global_position + globals.rand_vec(25,20,25,20,25,20)
			var forw = global_position - bd.global_position
			initial_velocity = forw.cross(bd.initial_velocity).normalized() * randf_range(9,6)
		print(name,"位置:",global_position,"\n初速度：",initial_velocity,"\n质量：",mass)
	
	#更新速度
	velocity = globals.velocity_update(total_force,mass,delta * time_scale,velocity)
	
	if name == "planet" and velocity.length() > 15:
		velocity = velocity.normalized() * 15
	elif name != "planet" and velocity.length() > 30:
		velocity = velocity.normalized() * 30
	
	#更新位置
	global_position += velocity * delta
	#print(name,"已经更新位置",global_position)
	#print(name, " 速度: ", velocity.length())
	
func _deferred_reload():
	if get_tree():
		get_tree().reload_current_scene()
