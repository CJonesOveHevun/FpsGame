extends Control

onready var container = $plr_container
onready var timer = $interval
onready var ready_b = $ready_button
onready var ready_label = $ready_label
onready var mode_option = $modeOption
onready var start_b = $start_b
onready var map_name = $map_name
onready var map_container = $maps_container
onready var deathmatch_maps = $maps_container/deathmatch_maps
onready var teammatch_maps = $maps_container/teammatch_maps
onready var match_mode = $match_mode
var plr_ready : int
var server_ready : int

onready var maps = {"Cargo" : load("res://Scenes/Maps/map_cargo.tscn"),
"Mansion" : load("res://Scenes/Maps/map_mansion.tscn"),
 "Office": load("res://Scenes/Maps/map_office.tscn"),
"Barns":load("res://Scenes/Maps/map_barns.tscn"),
"Shore":load("res://Scenes/Maps/map_shore.tscn")
}

func _ready() -> void:
	if !get_tree().is_network_server():
		ready_b.show()
	mode_option.connect("item_selected", self, "auto_change_map")
# warning-ignore:return_value_discarded
	get_parent().connect("plr_disconnect", self, "ready_dc")

func _process(_delta):
	deathmatch_maps.visible = mode_option.selected == 0
	teammatch_maps.visible = mode_option.selected == 1
	if get_tree().is_network_server():
		for f in map_container.get_children():
			for i in f.get_children():
				if i.pressed:
					map_name.text = i.text
					i.release_focus()

func auto_change_map(selected):
	match selected:
		0:
			map_name.text = "Cargo"
		1:
			map_name.text = "Shore"

sync func sync_mode(mode):
	ServerInfo.servertype = mode
	return

remote func update_players():
	var num_of_plr : int
	if Players.get_child_count() > 0:
		for i in container.get_children():
			#i.queue_free()
			i.call_deferred("queue_free")
		for e in Players.get_children():
			var new_label = Label.new()
			new_label.clip_text = true
			new_label.text = str(e.username)
			container.call_deferred("add_child", new_label, true)
		
		num_of_plr = Players.get_child_count() - 1
		ready_label.text = "No. of players ready: %s/%s" % [plr_ready,num_of_plr]
	if get_tree().is_network_server():
		mode_option.disabled = false
		match_mode.disabled = false
		map_container.show()
		server_ready = plr_ready
		if plr_ready == num_of_plr && plr_ready > 0:
			start_b.show()
		else:
			start_b.hide()
		rpc("update_ready", server_ready, map_name.text)

func _on_menu_button_pressed():
	Networking.reset_server()
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene();

func _on_interval_timeout():
	if get_tree().is_network_server():
		update_players()
		rpc("update_players")

remotesync func update_ready(num: int, map: String):
	plr_ready = num
	map_name.text = map

func _on_ready_button_pressed():
	ready_b.disabled = true
	rpc("add_plr_ready")

sync func add_plr_ready():
	plr_ready += 1

func ready_dc():
	if plr_ready > 0:
		plr_ready -= 1

var thread = Thread.new()

func _on_start_b_pressed():
	if get_tree().is_network_server():
		rpc("change_map", map_name.text)
		start_b.disabled = true

sync func short_match():
	ServerInfo.dm_kill_limit = 8 #8
	ServerInfo.tm_score_limit = 5 #5
sync func casual_match():
	ServerInfo.dm_kill_limit = 15 #15
	ServerInfo.tm_score_limit = 7 #7
sync func long_match():
	ServerInfo.dm_kill_limit = 25 #25
	ServerInfo.tm_score_limit = 15 #15

sync func change_map(map):
# warning-ignore:unused_variable
	var spawn = get_tree().get_nodes_in_group("dm_pos")
	var invincibility = preload("res://Scenes/effects/invincibilty.tscn")
	ServerInfo.servertype = mode_option.selected
	rpc("sync_mode" , ServerInfo.servertype)
	ServerInfo.isMatchStart = true
	if ServerInfo.servertype == 0:
		for p in Players.get_children():
			randomize()
			p.add_child(invincibility.instance(), true)
			p.translation = Vector3(rand_range(-10,10), 0, rand_range(-10,10))
		if get_tree().is_network_server():
			if match_mode.selected == 0:
				rpc("short_match")
			elif match_mode.selected == 1:
				rpc("casual_match")
			else:
				rpc("long_match")
	elif ServerInfo.servertype == 1:
		var chosen_team : int = 1
		for p in Players.get_children():
			if chosen_team == 1:
				p.team = chosen_team
				chosen_team = 2
				for point in get_tree().get_nodes_in_group("team1pos"):
					p.translation = point.translation
			else:
				p.team = chosen_team
				chosen_team = 1
				for point in get_tree().get_nodes_in_group("team2pos"):
					p.translation = point.translation
			if get_tree().is_network_server():
				if match_mode.selected == 0:
					rpc("short_match")
				elif match_mode.selected == 1:
					rpc("casual_match")
				else:
					rpc("long_match")
			p.add_child(invincibility.instance(), true)
		print("Coming soon!")
		#get_tree().change_scene_to(Networking.main_menu)
		#Networking.reset_server()
	if get_tree().is_network_server():
		get_tree().network_peer.refuse_new_connections = true
	load_map_async(map)

func load_map_async(map):
	get_tree().call_deferred("change_scene_to", (maps[map]))
