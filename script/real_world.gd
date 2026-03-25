extends Node3D

@onready var stars = {
	"A": $Body/A/A,
	"B": $Body/B/B,
	"C": $Body/C/C,
	"planet": $Body/Planet2
}
@onready var player = $Player

func _process(delta):
	player.global_position = Vector3(3560,0,0)
	var posP = DataBridge.star_positions.get("planet")
	stars["planet"].global_position = Vector3.ZERO
	
	for name in ["A", "B", "C"]:
			var sim_pos = DataBridge.star_positions.get(name)
			if sim_pos == null:
				continue
			var offset = sim_pos - posP
			stars[name].global_position = offset * 300.0
