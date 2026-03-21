extends Node3D

@onready var stars = {
	"A": $Body/A,
	"B": $Body/B,
	"C": $Body/C,
	"planet": $Body/Planet
}

func _process(delta):
	var posP = DataBridge.star_positions.get("planet")
	stars["planet"].global_position = Vector3.ZERO
	
	for name in ["A", "B", "C"]:
			var sim_pos = DataBridge.star_positions.get(name)
			if sim_pos == null:
				continue
			var offset = sim_pos - posP
			stars[name].global_position = offset * 300.0
