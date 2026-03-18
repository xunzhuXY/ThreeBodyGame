extends Node

var radius:float
var maxd:float = 500
var center:Vector3

const G =0.3 

#dv是delta_vector(ΔV，速度，而且为向量)
#forward_vec指向另一颗星星的向量
#distance_sqr是距离的平方
#force_magnitude是引力的大小
#力的方向运算,指向 - 自己，
static func force_forward_calculation(Bodypos:Vector3,Selfpos:Vector3) -> Vector3:
	
	return (Bodypos - Selfpos)

	#计算引力公式：F = (G*m1*m2)/(R**2),m1是本身，m2是对象

#引力计算
static func Gravity_calculation(m1:float,m2:float,forward_vec:Vector3) -> Vector3:
	var distance_sqr = forward_vec.length_squared()
	if distance_sqr == 0:
		return Vector3.ZERO

	var softing = 0.1 #软化因子，你也不想它飞出去吧
	var force_magnitude = (G * m1 * m2) / (distance_sqr + softing)
	return forward_vec.normalized() * force_magnitude

#速度更新
static func velocity_update(force:Vector3,mass:float,dt:float,v0:Vector3) -> Vector3:
	var acceleration = force / mass #求加速度
	var velocity = v0 + acceleration * dt #V = V0 + at 
	return velocity

#生成随机向量
static func rand_vec(x1:float,x2:float,y1:float,y2:float,z1:float,z2:float) -> Vector3:
	var x = randf_range(x1,x2)
	var y = randf_range(y1,y2)
	var z = randf_range(z1,z2)
	return Vector3(x,y,z)

#碰撞检测
static func collision_end(A:Node3D,B:Node3D) -> bool:
	var meshA = A.get_node_or_null("MeshInstance3D")
	var meshB = B.get_node_or_null("MeshInstance3D")
	if meshA and meshA.mesh is SphereMesh and meshB and meshB.mesh is SphereMesh:
		var sphereA = meshA.mesh as SphereMesh
		var sphereB = meshB.mesh as SphereMesh
		var dist_vec = B.global_position - A.global_position
		return dist_vec.length() <= (sphereA.radius + sphereB.radius) * 0.75
	return false

#三个飞星检测
static func three_flying_stars(
planet: Node3D,
stars: Array,
angle_threshold_deg: float =9.0,
distance_threshold: float = 400.0
) -> bool:
	# 1. 计算行星到每个恒星的向量
	var vectors = []
	for star in stars:
		vectors.append(star.global_position - planet.global_position)

	# 2. 两两检查夹角
	var angle_thresh_rad = deg_to_rad(angle_threshold_deg)
	for i in range(vectors.size()):
		for j in range(i+1, vectors.size()):
			var angle = vectors[i].angle_to(vectors[j])
			if angle > angle_thresh_rad:
				return false

	# 3. 计算系统质心（假设恒星质量不等，若质量相等可用几何平均）
	var total_mass = 0.0
	var weighted_sum = Vector3.ZERO
	for star in stars:
		var mass = star.get("mass")  # 假设恒星脚本有 mass 属性
		if mass == null:
			mass = 1.0  # 默认质量相等
		total_mass += mass
		weighted_sum += star.global_position * mass

	if total_mass == 0:
		return false
	var centroid = weighted_sum / total_mass

	# 4. 计算行星到质心的距离
	var dist_to_center = planet.global_position.distance_to(centroid)
	return dist_to_center > distance_threshold

#飞星检测
static func too_far(planet:Node3D,stars:Array)->bool:
	var maxd:float = 800
	var dis1 = (planet.global_position - stars[0].global_position).length()
	var dis2 = (planet.global_position - stars[1].global_position).length()
	var dis3 = (planet.global_position - stars[2].global_position).length()
	if dis1 > maxd and dis2 > maxd and dis3 > maxd:
		return true
	return false


static func center_pos(stars:Array)->Vector3:
	var total_mass = 0.0
	var weighted_sum = Vector3.ZERO
	for star in stars:
		var mass = star.get("mass")  # 假设恒星脚本有 mass 属性
		if mass == null:
			mass = 1.0  # 默认质量相等
		total_mass += mass
		weighted_sum += star.global_position * mass

	if total_mass == 0:
		return Vector3.ZERO
	var centroid = weighted_sum / total_mass
	return centroid
