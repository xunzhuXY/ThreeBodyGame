@tool
class_name NoiseLayer
extends Resource

@export var frequency: float = 0.05          # 频率
@export var amplitude: float = 5.0           # 振幅
@export var fractal_octaves: int = 3         # 分形细节度 (octaves)
@export var fractal_lacunarity: float = 2.0  # 频率倍增,值偏大，细节会非常细碎
@export var fractal_gain: float = 0.5        # 振幅衰减,值越小，地形更“平滑”
@export var only_on_surface: bool = false    # 是否只在现有地表添加
@export var is_cave : bool = false
@export var min_radius: float = 0.0          # 生效的最小径向距离
@export var max_radius: float = INF          # 生效的最大径向距离
