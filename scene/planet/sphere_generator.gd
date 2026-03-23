# sphere_generator.gd
@tool
extends VoxelGeneratorScript

const SDF_CHANNEL = VoxelBuffer.CHANNEL_SDF

@export var radius: float = 50.0
@export var seed: int = 0

@export var layers: Array[NoiseLayer] = []
@export var ZNlayers: Array[ZN_NoiseLayer] = []

#噪声实例
var noise_instances: Array[FastNoiseLite] = []
var znnoise_instances: Array[ZN_FastNoiseLite] = []
var _mutex: Mutex

func _init() -> void:
	_mutex = Mutex.new()

func _get_used_channels_mask() -> int:
	return 1 << SDF_CHANNEL

func _generate_block(buffer:VoxelBuffer,origin:Vector3i,lod:int):
	#lod为0是是空气
	if lod != 0:
		return
	_mutex.lock()
	# 根据层配置创建噪声实例（只创建一次）
	if noise_instances.size() != layers.size():
		noise_instances.clear()
		for layer in layers:
			var n = FastNoiseLite.new()
			n.noise_type = FastNoiseLite.TYPE_PERLIN
			n.seed = seed
			n.fractal_type = FastNoiseLite.FRACTAL_FBM
			n.fractal_octaves = layer.fractal_octaves
			n.fractal_lacunarity = 2.0
			n.fractal_gain = 0.5
			noise_instances.append(n)
	var local_instances = noise_instances.duplicate()
	_mutex.unlock()
	#if noise_instances.is_empty():
		#for layer in layers:
			##遍历每一个噪声
			#var n = FastNoiseLite.new()                 #创建噪声
			#n.noise_type = FastNoiseLite.TYPE_PERLIN   #设置噪声类型
			#n.seed = seed                               #设置种子
			#n.fractal_type = FastNoiseLite.FRACTAL_FBM  #分型类型,fractal用于细节化噪声
			#n.fractal_octaves = layer.fractal_octaves      #层数
			#n.fractal_lacunarity = layer.fractal_lacunarity #频率倍增
			#n.fractal_gain = layer.fractal_gain
			#noise_instances.append(n)                   #加入到数组末尾
	
	
	#if znnoise_instances.is_empty():
		#for layer in ZNlayers:
			##遍历每一个噪声
			#var n = ZN_FastNoiseLite.new()                       #创建噪声
			#n.noise_type = ZN_FastNoiseLite.TYPE_OPEN_SIMPLEX_2   #设置噪声类型
			#n.seed = seed
			#n.period = layer.period                              #设置种子
			#n.fractal_type = ZN_FastNoiseLite.FRACTAL_FBM         #分型类型,fractal用于细节化噪声
			#n.fractal_octaves  = layer.fractal_octaves                #层数
			#n.fractal_lacunarity = layer.fractal_lacunar          #频率倍增
			#n.fractal_gain = layer.fractal_gain
			#znnoise_instances.append(n)                            #加入到数组末尾
	
	var size = buffer.get_size() #获取顶点点位
	var layer_count = layers.size() #获取噪声层数
	#var ZNlayer_count = ZNlayers.size()
	
	#遍历每一个顶点
	for x in size.x:
		for y in size.y:
			for z in size.z:
				var pos = origin + Vector3i(x,y,z)         #获取绝对坐标
				var world_pos = Vector3(pos.x,pos.y,pos.z) #转换为世界坐标
				var r = world_pos.length()                 #计算体素到原点的距离
				var sphere_dist = r                        #(距离球心的高度)
				
				var target_dist = radius                   #可以理解为基础距离,最初为半径
														   #sdf:体素到表面的距离
				var current_sdf = sphere_dist - target_dist#0:表面，正:空气,负:固体
				
				#遍历每一层噪音
				for i in layer_count:
					var layer = layers[i]
					var noise = noise_instances[i]
					#var znlayer = ZNlayers[i]
					#var znnoise = znnoise_instances[i]
					
					#检查高度范围,主人要求的喵,不在范围就不管了
					if r < layer.min_radius or r > layer.max_radius:
						continue
					#if r < znlayer.min_radius or r > znlayer.max_radius:
						#continue
					
					#采样噪声
					var n = noise.get_noise_3d(
						world_pos.x * layer.frequency,  #频率
						world_pos.y * layer.frequency,
						world_pos.z * layer.frequency
					)
					var add_noise = n * layer.amplitude #振幅
					
					#var znn = znnoise.get_noise_3d(
						#world_pos.x * znlayer.period,
						#world_pos.y * znlayer.period,
						#world_pos.z * znlayer.period
					#)
					#var add_znnoise = znn * znlayer.amplitude
					
					# 如果该层限制只在现有地表附近添加，则根据当前 SDF 值进行衰减
					# 保证噪音只生成在我想让它生成的地方
					if layer.only_on_surface:
						# 定义“表面附近”的宽度（例如 5.0 个单位）
						var surface_width = 5.0
						# 距离表面越远，权重越小（线性衰减）
						var distance_to_face = abs(current_sdf)
						var weight = clamp(1.0 - distance_to_face / surface_width,0.0,1.0)
						add_noise *= weight
					#if znlayer.only_on_surface:
						## 定义“表面附近”的宽度（例如 5.0 个单位）
						#var surface_width = 5.0
						## 距离表面越远，权重越小（线性衰减）
						#var distance_to_face = abs(current_sdf)
						#var weight = clamp(1.0 - distance_to_face / surface_width,0.0,1.0)
						#add_znnoise *= weight
					
					#if znlayer.sea_level:
						#if r < znlayer.min_radius:
							#add_znnoise = 0.0
							#print(add_znnoise)
					if layer.is_cave:
						add_noise = -abs(add_noise)
						
					target_dist += add_noise
					#target_dist += add_znnoise
					current_sdf = sphere_dist - target_dist
					
					
				buffer.set_voxel_f(current_sdf, x, y, z, SDF_CHANNEL)
