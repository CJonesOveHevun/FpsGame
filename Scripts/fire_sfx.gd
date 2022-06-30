extends AudioStreamPlayer3D
class_name sfx_timeout

func _ready():
	return connect("finished",self, "destroy")


func destroy():
	queue_free()
