extends Node

var radius:float

const G = 5

#dv是delta_vector(ΔV，速度，而且为向量)
#forward_vec指向另一颗星星的向量
#distance_sqr是距离的平方
#force_magnitude是引力的大小

#力的方向运算,指向 - 自己，
static func force_forward_calculation(Bodypos:Vector3,Selfpos:Vector3) -> Vector3:
	return (Bodypos - Selfpos)

#计算引力公式：F = (G*m1*m2)/(R**2),m1是本身，m2是对象
static func Gravity_calculation(m1:float,m2:float,forward_vec:Vector3) -> Vector3:
	var distance_sqr = forward_vec.length_squared()
	if distance_sqr == 0:
		return Vector3.ZERO
	
	var softing = 5.0 #软化因子，你也不想它飞出去吧
	
	var force_magnitude = (G * m1 * m2) / (distance_sqr + softing)
	return forward_vec.normalized() * force_magnitude

#速度更新
static func velocity_update(force:Vector3,mass:float,dt:float,v0:Vector3) -> Vector3:
	var acceleration = force / mass #求加速度
	var velocity = v0 + acceleration * dt #V = V0 + at 
	return velocity

#生成随机向量
static  func rand_vec(x1:float,x2:float,y1:float,y2:float,z1:float,z2:float) -> Vector3:
	var x = randf_range(x1,x2)
	var y = randf_range(y1,y2)
	var z = randf_range(z1,z2)
	return Vector3(x,y,z)
