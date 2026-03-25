extends CharacterBody3D

@export var gravity_strength = 9.8 # 千米/秒²，相当于 9.8 m/s² 转换为千米
@export var walk_speed = 10      # 千米/秒
@export var jump_velocity = 10     # 千米/秒
@export var mouse_sensitivity = 0.001 #灵敏度
@export var player_scale = 1
@export var block_size = 2
@export var _light_on:bool = false

@onready var _indicator := $indicator
@onready var planet = $"../../Body/Planet2"
@onready var light = $Camera3D/SpotLight3D

var terrain: VoxelLodTerrain
var voxel_tool: VoxelTool

var yaw = 0.0
var pitch = 0.0
var pause = false

func _ready():
	_indicator.visible = false
	walk_speed = 10
	jump_velocity = 10
	gravity_strength = 9.8
	scale = Vector3.ONE * player_scale
	#寻找路径以计算相对位置
	planet = get_node("../../Body/Planet2") 
	terrain = get_node("../../Body/Planet2/VoxelLodTerrain2")
	# 从地形获取 VoxelTool 实例
	if terrain:
		voxel_tool = terrain.get_voxel_tool()
	else:
		print("Terrain not found!")
		return
	
	# 可选：设置默认通道为 SDF（默认就是）
	voxel_tool.set_channel(VoxelBuffer.CHANNEL_SDF)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$Camera3D.position = Vector3(0, 0.5, 0)
	$Camera3D/SpotLight3D.position = Vector3(0,0.5,0)
	floor_max_angle = deg_to_rad(75)
	to_the_ground()

func _process(delta):
	if gravity_strength == null:
		gravity_strength = 0.98
	#1. 重力方向
	var down = (planet.global_position - global_position).normalized()
	var up = -down
	#更新物理引擎的向上方向，让 is_on_floor() 正确工作
	up_direction = up
	
	#2. 应用重力
	velocity += down * gravity_strength * delta
	
	#3. 获取摄像机视角的方向，并投影到切平面（与 down 垂直）
	var camera = $Camera3D
	var cam_from = camera.global_position
	var cam_forward = -camera.global_transform.basis.z
	var cam_right = camera.global_transform.basis.x
	var cam_space_state = get_world_3d().direct_space_state
	var cam_query = PhysicsRayQueryParameters3D.create(cam_from, cam_from + cam_forward * 50.0)
	cam_query.exclude = [self]
	var cam_hit = cam_space_state.intersect_ray(cam_query)
	
	#显示放置位置
	if cam_hit and cam_hit.collider is VoxelLodTerrain:
		_indicator.global_position = cam_hit.position
		_indicator.visible = true
	else:
		_indicator.visible = false
	
	# 投影到切平面（去掉径向分量），并归一化
	cam_forward = (cam_forward - cam_forward.dot(down) * down).normalized()
	cam_right = (cam_right - cam_right.dot(down) * down).normalized()
	
	# 4. 获取输入并计算移动方向
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (cam_forward * (-input_dir.y) + cam_right * input_dir.x).normalized()
	
	# 5. 更新速度：切向速度 + 径向速度（保留重力影响）
	var radial_vel = velocity.dot(down) #竖直速度
	var tangent_vel = direction * walk_speed if direction.length() > 0 else Vector3.ZERO
	velocity = tangent_vel + down * radial_vel
	
	# 6. 跳跃检测（增加射线辅助，防止因短暂离地而错过）
	var grounded = is_on_floor()
	if not grounded:
		var space_state = get_world_3d().direct_space_state
		var from = global_position
		var to = from + down * 0.3
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [self]
		var hit = space_state.intersect_ray(query)
		if hit and from.distance_to(hit.position) < 0.25:
			grounded = true
	if Input.is_action_just_pressed("jump") and grounded:
		velocity += -down * jump_velocity
	
	# 7. 执行移动
	move_and_slide()
	#防止被埋
	_process_undig()
	
	# 8. 更新玩家朝向：让玩家模型始终面朝 yaw 方向，且保持“向上”为 up
	# 获取摄像机在切平面内的方向作为参考
	var ref_forward = cam_forward
	if ref_forward.length() < 0.0001:
		ref_forward = cam_right
		ref_forward = ref_forward.normalized()
	# 绕 up 轴旋转 yaw，得到玩家前向
	var player_forward = ref_forward.rotated(up, yaw).normalized()
	yaw = 0
	# 使用 looking_at 构造基向量：Z 轴指向 player_forward，Y 轴尽量指向 up
	# 这能保证角色始终直立，不会“躺下”
	global_transform.basis = Basis.looking_at(player_forward, up)
	scale = Vector3.ONE * player_scale
	
	 # 9. 设置摄像机的垂直旋转（抬头低头）
	$Camera3D.rotation.x = pitch
	$Camera3D/SpotLight3D.rotation.x = pitch * 0.25
	

func _input(event):
	if Input.is_action_just_pressed("dig"):   # 假设左键绑定 "dig"
		var target = get_target_voxel()
		if target.hit:
			#print("Digging at: ", target.voxel_pos)
			dig_voxel(target.hit_point)
	elif Input.is_action_just_pressed("place"): # 假设右键绑定 "place"
		var target = get_target_voxel()
		if target.hit:
			place_voxel(target.hit_point)  
	if Input.is_action_just_pressed("light"):
		_light_on = !_light_on
		if _light_on:
			light.visible = true
		else:
			light.visible = false
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.relative.length() > 0.001:
			if mouse_sensitivity == null:
				mouse_sensitivity = 0.001
			# 水平旋转（左右）
			yaw -= event.relative.x * mouse_sensitivity
			# 垂直旋转（上下），限制角度避免翻转
			pitch -= event.relative.y * mouse_sensitivity
			pitch = clamp(pitch, -1.5, 1.5)   # 约 -85° 到 85°
	#if Input.is_action_just_pressed("pause"):
		#get_tree().paused = not get_tree().paused
		#
		#if get_tree().paused:
			#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			##get_tree().paused = true
		#else:
			#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			##get_tree().paused = false

func to_the_ground():
	if not planet:
		#print("Planet is null")
		return
	
	# 重力方向（指向行星中心）
	var down = (planet.global_position - global_position).normalized()
	
	 # 从玩家当前位置沿重力方向发射射线
	var space_state = get_world_3d().direct_space_state
	var from = global_position
	var to = from + down * 1000.0   # 向下检测足够远的距离
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit = space_state.intersect_ray(query)
	
	if hit:
		print("Hit ground at: ", hit.position)
		# 射线命中点
		var hit_point = hit.position
		# 计算玩家脚部到射线命中点的距离（胶囊体半高）
		var capsule_height = $CollisionShape3D.shape.height  # 假设你的碰撞形状是 CapsuleShape3D
		var foot_offset = capsule_height * 100
		# 新位置：命中点 + 向上（反重力方向）偏移 foot_offset
		global_position = hit_point - down * foot_offset
		velocity = Vector3.ZERO
		move_and_slide()

func get_target_voxel(max_distance: float = 50.0) -> Dictionary:
	var camera = get_viewport().get_camera_3d()
	var from = camera.global_position
	var direction = -camera.global_transform.basis.z
	var result = voxel_tool.raycast(from, direction, max_distance)
	if result:
		return {"hit": true, "normal": result.normal, "hit_point": result.position}
	return {"hit": false}

func dig_voxel(hit_point: Vector3):
	var local_pos = terrain.global_transform.affine_inverse() * hit_point
	voxel_tool.mode = VoxelTool.MODE_REMOVE
	voxel_tool.do_sphere(local_pos, block_size)

func place_voxel(hit_point: Vector3):
	var local_pos = terrain.global_transform.affine_inverse() * hit_point
	voxel_tool.mode = VoxelTool.MODE_ADD
	voxel_tool.do_sphere(local_pos, block_size)

#防止卡地里面
func _process_undig():
	if not terrain:
		return
	var vt : VoxelTool = terrain.get_voxel_tool()
	var to_local := terrain.global_transform.affine_inverse()
	var local_pos := to_local * global_position
	vt.channel = VoxelBuffer.CHANNEL_SDF
	var sdf: float = vt.get_voxel_f_interpolated(local_pos)
	if sdf < -0.001:  # 被埋了（在固体内部）
		#print("Character is buried, teleporting back to air")
		var up := local_pos.normalized()
		var offset_local_pos := local_pos
		for i in 10:
			offset_local_pos += 0.2 * up   # 沿径向向上移动
			sdf = vt.get_voxel_f_interpolated(offset_local_pos)
			if sdf > 0.0005:
				break
		var new_global_pos = terrain.global_transform * offset_local_pos
		global_position = new_global_pos
		velocity = Vector3.ZERO
