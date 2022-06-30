extends Spatial

func _ready():
	for e in get_tree().get_nodes_in_group("roomM"):
		e.active = true
		e.rooms_convert()
