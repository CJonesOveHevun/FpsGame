extends Control

signal plr_disconnect
#
onready var training_map = load("res://Scenes/Maps/map_training_mode.tscn")
onready var broadcast_server = preload("res://Scenes/Prefabs/server_broadcaster.tscn")
onready var plr = preload("res://Scenes/Characters/player.tscn")
onready var settings = preload("res://Scenes/Prefabs/Settings.tscn")
onready var menu_char = $menu_env/menu_bg/character_fps/skeleton_game_rig/Skeleton/whole_body
#
onready var join_button = $Base/join_b
onready var lobby_button = $Base/host_b
onready var training_button = $Base/training_b
onready var ip_label = $Base/ip_label
onready var plr_cap = $Base/spin_cap
onready var menu_cam = $menu_env/Camera
onready var bg = $menu_env/menu_bg
var thread
#
func _ready():
	thread = Thread.new()
	menu_char.get("material/0").albedo_color = Settings.plr_color
	ip_label.text = Networking.ip_address
	# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_connected", self, "_player_connected")
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_connected_to_server")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_connection_failed")

func _player_connected(id):
	print("hello there %s" %[id])
	instance_player(id)

func _player_disconnected(id):
	print("%s left the game" %[id])
	emit_signal("plr_disconnect")
	if Players.has_node(str(id)):
		Players.get_node(str(id)).queue_free()

remotesync func _server_disconnected():
	Networking.reset_server()
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func _connected_to_server():
	var open_lobby = Networking.server_lobby.instance()
	bg.visible = false
	if !get_tree().is_network_server():
		get_tree().current_scene.add_child(open_lobby, true)
		open_lobby.timer.start()
		get_node("Server_browser").queue_free()
		instance_player(get_tree().get_network_unique_id())

func _connection_failed():
	print("ehh")

func _on_lobby_created() -> void:
	Networking.create_server()
	Networking.server.always_ordered = true
	
	find_node("Base").hide()
	bg.visible = false
	var open_lobby = Networking.server_lobby.instance()
	get_tree().current_scene.add_child(open_lobby, true)
	instance_player(get_tree().get_network_unique_id())
	open_lobby.update_players()
	print("hosting")

	var svr_bc = broadcast_server.instance()
	open_lobby.add_child(svr_bc, true)

func _on_browser_opened()->void:
	find_node("Base").hide()
	print("finding servers...")
	var open_browser = Networking.server_browser.instance()
	get_tree().current_scene.add_child(open_browser, true)

func instance_player(id) -> void:
	var player_instance = ServerInfo.instance_node(plr, Players)
	player_instance.name = str(id)
	player_instance.rpc("update_weapon_model", player_instance.current_gun)
	player_instance.set_network_master(id)
	player_instance.rpc("_set_name")

func _on_training_b_pressed():
	Networking.create_server()
	Networking.server.refuse_new_connections = true
	instance_player(get_tree().get_network_unique_id())
	thread.start(self, "training_map_async" , training_map)
	ServerInfo.isMatchStart = true
	thread.call_deferred("wait_to_finish")

func training_map_async(map: PackedScene):
	get_tree().call_deferred("change_scene_to", map)

func _on_spin_cap_value_changed(value):
	Networking.max_clients = value
	plr_cap.release_focus()

func _on_settings_b_pressed():
# warning-ignore:return_value_discarded	
	get_tree().call_deferred("change_scene_to",settings)

func _input(event):
	if event is InputEventMouseMotion:
		var drag = -event.relative
		var threshold = 3
		if drag.x > threshold:
			menu_cam.rotation_degrees.y = lerp_angle(menu_cam.rotation_degrees.y,menu_cam.rotation_degrees.y + 3 / 2,0.1)
		elif drag.x < -threshold:
			menu_cam.rotation_degrees.y = lerp_angle(menu_cam.rotation_degrees.y,menu_cam.rotation_degrees.y - 3 / 2,0.1)
		else:
			menu_cam.rotation_degrees.y = lerp(menu_cam.rotation_degrees.y, -99.735, 0.01)
		if drag.y > threshold:
			menu_cam.rotation_degrees.x = lerp_angle(menu_cam.rotation_degrees.x,menu_cam.rotation_degrees.x + 3 / 2,0.1)
		elif drag.y < -threshold:
			menu_cam.rotation_degrees.x = lerp_angle(menu_cam.rotation_degrees.x,menu_cam.rotation_degrees.x - 3 / 2,0.1)
		else:
			menu_cam.rotation_degrees.x = lerp(menu_cam.rotation_degrees.x, 0, 0.1)
