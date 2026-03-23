@tool
class_name ZN_NoiseLayer
extends Resource

@export var seed: int = 0
@export var period: float = 64.0            #周期
@export var amplitude: float = 1.0
@export var fractal_octaves: int = 3
@export var fractal_lacunar:float = 2.0
@export var fractal_gain: float = 0.5 
@export var only_on_surface: bool = false    # 是否只在现有地表添加
@export var min_radius: float = 0.0          # 生效的最小径向距离
@export var max_radius: float = INF          # 生效的最大径向距离
@export var sea_level: bool = false
