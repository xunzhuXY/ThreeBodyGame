extends Node3D

@export var mass:float = 1.0 #质量
@export var initial_velocity:Vector3 = Vector3.ZERO #初速度
@export var color:Color = Color.WHITE #颜色，用于区分
@export var is_star:bool = true
@export var velocity: Vector3
@export var Lifetime:float = 1000

var time_scale = 1.0 #时间尺度

func _ready():
	#print(name, " 的 color = ", color)
	velocity = initial_velocity
	add_to_group("Universe")
	#print(name,"已入组")
	
	#随机生成，位置与速度还有质量
	
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
		GPUParticles.lifetime = 20
		GPUParticles.trail_lifetime = 100
		GPUParticles.amount = 100
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
		
		#结束判断
		var distance = body.global_position - global_position
		var MeshInstance = get_node_or_null("MeshInstance3D")
		if MeshInstance and MeshInstance.mesh is SphereMesh:
			var spheremesh = MeshInstance.mesh as SphereMesh
			globals.radius = spheremesh.radius
			if name == "C":
				print(name," ",globals.radius," ",distance.length())
			if distance.length() <= globals.radius:
				get_tree().quit()
			
			
		#引力的方向
		var forward = globals.force_forward_calculation(body.global_position,global_position)
		#分开计算引力
		var force = globals.Gravity_calculation(mass,body.mass,forward)
		#引力合力
		total_force += force
		
	#print(name,"当前合力为",total_force)
	
	#更新速度
	velocity = globals.velocity_update(total_force,mass,delta,velocity) * time_scale
	if name == "planet" and velocity.length() > 50:
		velocity = velocity.normalized() *  50
	elif name != "planet" and velocity.length()>60:
		velocity = velocity.normalized() *  60
	#更新位置
	global_position += velocity * delta
	#print(name,"已经更新位置",global_position)
	#print(name, " 速度: ", velocity.length())
