extends Control

onready var time = $respawn_time
onready var lbl = $timer_spawn_lbl
var fixed_seconds : float
var parent

func _ready():
# warning-ignore:return_value_discarded
	ServerInfo.connect("matchOver", self,"abort_timer")
	parent = get_parent()
	if parent.is_network_master():
		var num_plrs = Players.get_child_count()
		fixed_seconds = 8.0 + num_plrs
		time.start()
		lbl.text = "Respawning in... %s" % [fixed_seconds]
	else:
		call_deferred("queue_free")

func abort_timer():
	queue_free()

func _on_respawn_time_timeout():
	if fixed_seconds > 0:
		fixed_seconds -= 1
		lbl.text = "Respawning in... %s" % [fixed_seconds]
	else:
		lbl.text = "Respawning now!"
		respawn_plr()
		call_deferred("queue_free")


sync func respawn_plr():
	var get_type = ServerInfo.servertype
	parent.rpc("respawn", get_type)
