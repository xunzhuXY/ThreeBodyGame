extends DirectionalLight3D
@export var disAP:Vector3
@export var disBP:Vector3
@export var disCP:Vector3

@export var AP:float
@export var BP:float
@export var CP:float

@onready var stars = {
	"A": $"../../Body/A",
	"B": $"../../Body/B",
	"C": $"../../Body/C",
	"planet":$"../../Body/Planet"
}

func _process(delat):
	disAP = stars["A"].global_position
	disBP = stars["B"].global_position
	disCP = stars["C"].global_position
	AP = disAP.length()
	BP = disBP.length()
	CP = disCP.length()
	if name == "Alight":
		global_position = disAP
		light_energy = 1 * 440 / AP
	elif name == "Blight":
		global_position = disBP
		light_energy = 1 * 480 / BP
	elif name == "Clight":
		global_position = disCP
		light_energy = 1 * 400 / CP
	$".".global_transform.basis = Basis.looking_at(-global_position, Vector3.UP)
