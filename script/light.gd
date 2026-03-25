extends DirectionalLight3D

@export var disAP:Vector3
@export var disBP:Vector3
@export var disCP:Vector3

@export var AP:float
@export var BP:float
@export var CP:float

@onready var stars = {
	"A": $"../../Body/A/A",
	"B": $"../../Body/B/B",
	"C": $"../../Body/C/C",
	"planet":$"../../Body/Planet2"
}
@onready var player = $"../../Player/CharacterBody3D"

func _process(delat):
	var player_pos = player.global_position
	var planet_center = stars["planet"].global_position
	var to_planet = -(planet_center - player_pos).normalized()
	var to_sun = (global_position - player_pos).normalized()
	var dot = to_sun.dot(to_planet)
	visible = dot > 0.0
	disAP = stars["A"].global_position
	disBP = stars["B"].global_position
	disCP = stars["C"].global_position
	AP = disAP.length()
	BP = disBP.length()
	CP = disCP.length()
	if name == "Alight":
		global_position = disAP
		light_energy = 1 * 90000 / AP
	elif name == "Blight":
		global_position = disBP
		light_energy = 1 * 100000 / BP
	elif name == "Clight":
		global_position = disCP
		light_energy = 1 * 80000 / CP
	global_transform.basis = Basis.looking_at(-global_position, Vector3.UP)
