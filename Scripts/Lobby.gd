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
var plr_ready : int
var server_ready : int

onready var maps = {"Cargo" : preload("res://Scenes/Maps/map_cargo.tscn"),
"Mansion" : preload("res://Scenes/Maps/map_mansion.tscn"),
 "Office":preload("res://Scenes/Maps/map_office.tscn")}

func _ready() -> void:
	if !get_tree().is_network_server():
		ready_b.show()
# warning-ignore:return_value_discarded
	get_parent().connect("plr_disconnect", self, "ready_dc")

func _process(_delta):
	deathmatch_maps.visible = mode_option.selected == 0
	for i in deathmatch_maps.get_children():
		if i.pressed:
			map_name.text = i.text
			i.release_focus()

sync func update_players():
	var num_of_plr : int
	if Players.get_child_count() > 0:
		for i in container.get_children():
			i.queue_free()
		for e in Players.get_children():
			var new_label = Label.new()
			new_label.text = str(e.name)
			container.add_child(new_label, true)
		
		num_of_plr = Players.get_child_count() - 1
		ready_label.text = "No. of players ready: %s/%s" % [plr_ready,num_of_plr]
	if get_tree().is_network_server():
		mode_option.disabled = false
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
		rpc("update_players")

remotesync func update_ready(num: int, map: String):
	plr_ready = num
	map_name.text = map

func _on_ready_button_pressed():
	print("ready")
	ready_b.disabled = true
	rpc("add_plr_ready")

sync func add_plr_ready():
	plr_ready += 1

func ready_dc():
	if plr_ready > 0:
		plr_ready -= 1

func _on_start_b_pressed():
	print("start!")
	if get_tree().is_network_server():
		rpc("change_map", map_name.text)
		start_b.disabled = true

sync func change_map(map):
	var spawn = get_tree().get_nodes_in_group("dm_pos")
	ServerInfo.servertype = mode_option.selected
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(maps[map])
	ServerInfo.isMatchStart = true
	if ServerInfo.servertype == 0:
		print(spawn)
		for p in Players.get_children():
			randomize()
			p.translation = Vector3(rand_range(-10,10), 0, rand_range(-10,10))
