extends Control

onready var dm_maps = $Control/maps/dm
onready var tm_maps = $Control/maps/tm
onready var timer = $Control/timer
onready var winner_lbl = $Control/lbl
var isChanging = false
var time = 15

onready var maps = {"Cargo":preload("res://Scenes/Maps/map_cargo.tscn"),
"Mansion":preload("res://Scenes/Maps/map_mansion.tscn"),
"Office":preload("res://Scenes/Maps/map_office.tscn"),
"Barns":preload("res://Scenes/Maps/map_barns.tscn"),
"Shore":preload("res://Scenes/Maps/map_shore.tscn")}

func _ready():
	dm_maps.visible = ServerInfo.servertype == 0
	tm_maps.visible = ServerInfo.servertype == 1
	if ServerInfo.servertype == 0:
		winner_lbl.text = ServerInfo.winner + " wins the match!"
	elif ServerInfo.servertype == 1:
		winner_lbl.text = ServerInfo.winner + " has won!"
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

remotesync func _process(_delta):
	for m in dm_maps.get_children():
		if m.pressed:
			rpc("_add_new_vote", m.get_child(0).text, m.name)
			disable_maps()
	for t in tm_maps.get_children():
		if t.pressed:
			rpc("_add_new_vote", t.get_child(0).text, t.name)
			disable_maps()

func _physics_process(delta):
	if time > 0:
		time -= delta
		timer.text = str(round(time))
	if time <= 0 && !isChanging:
		isChanging = true
		if get_tree().is_network_server():
			rpc("change_map")
	if Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE):
		return
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)



sync func change_map():
	var hv = 0
	var mgv = ""
	if ServerInfo.servertype == 0:
		for m in dm_maps.get_children():
			for v in m.get_children():
				if int(v.text) > 0 && hv < int(v.text):
					hv = int(v.text)
					mgv = v.get_parent().text
				else:
					pass
	if ServerInfo.servertype == 1:
		for t in tm_maps.get_children():
			for v in t.get_children():
				if int(v.text) > 0 && hv < int(v.text):
					hv = int(v.text)
					mgv = v.get_parent().text
				else:
					pass
	print(mgv)
	if mgv != "":
# warning-ignore:return_value_discarded
		get_tree().call_deferred("change_scene_to", maps[mgv])
		ServerInfo.isMatchStart = true
		ServerInfo.match_fin = false
		yield(get_tree().create_timer(2),"timeout")
		tp_plrs()
		call_deferred("queue_free")
	else:
# warning-ignore:return_value_discarded
		get_tree().call_deferred("reload_current_scene")
		ServerInfo.isMatchStart = true
		ServerInfo.match_fin = false
		yield(get_tree().create_timer(2),"timeout")
		tp_plrs()
		call_deferred("queue_free")

func tp_plrs():
	if ServerInfo.servertype == 0:
		for i in Players.get_children():
			randomize()
			i.state_reset()
			i.translation = Vector3(rand_range(-10,10), 0, rand_range(-10,10))
	if ServerInfo.servertype == 1:
		for y in Players.get_children():
			y.state_reset()
			if y.team == 1:
				for i in get_tree().get_nodes_in_group("team1pos"):
					y.translation = i.translation
			if y.team == 2:
				for i in get_tree().get_nodes_in_group("team2pos"):
					y.translation = i.translation

func disable_maps():
	for dm in dm_maps.get_children():
		dm.disabled = true
	for tm in tm_maps.get_children():
		tm.disabled = true

sync func _add_new_vote(child, parent):
	var vote: int = int(child)
	if ServerInfo.servertype == 0:
		dm_maps.get_node(parent).get_child(0).text = str(vote + 1)
	if ServerInfo.servertype == 1:
		tm_maps.get_node(parent).get_child(0).text = str(vote + 1)


func _on_b_menu_pressed():
	var main_scene = Networking.main_menu
	if get_tree().is_network_server():
		rpc("shutdown_server")
	else:
		rpc("notify_plrs", get_tree().get_network_unique_id())
# warning-ignore:return_value_discarded
		get_tree().change_scene_to(main_scene)
		Networking.reset_server()

sync func shutdown_server():
	var main_scene = Networking.main_menu
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(main_scene)
	Networking.reset_server()

sync func notify_plrs(id):
	Networking._player_disconnected(id)
