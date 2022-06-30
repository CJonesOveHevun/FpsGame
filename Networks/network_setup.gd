extends Control

signal plr_disconnect
#
onready var training_map = preload("res://Scenes/Maps/map_training_mode.tscn")
onready var broadcast_server = preload("res://Scenes/Prefabs/server_broadcaster.tscn")
onready var plr = preload("res://Scenes/Characters/player.tscn")
#
onready var join_button = $Base/join_b
onready var lobby_button = $Base/host_b
onready var training_button = $Base/training_b
onready var ip_label = $Base/ip_label
onready var plr_cap = $Base/spin_cap
#
func _ready():
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
	print("%s is gone" %[id])
	emit_signal("plr_disconnect")
	if Players.has_node(str(id)):
		Players.get_node(str(id)).queue_free()

remotesync func _server_disconnected():
	print("disconnected")
	Networking.reset_server()
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func _connected_to_server():
	print("someone joined!")
	var open_lobby = Networking.server_lobby.instance()
	if !get_tree().is_network_server():
		get_tree().current_scene.add_child(open_lobby, true)
		open_lobby.timer.start()
		get_node("Server_browser").queue_free()
		
		
		instance_player(get_tree().get_network_unique_id())

func _connection_failed():
	print("ehh")

func _on_lobby_created() -> void:
	Networking.create_server()
	
	find_node("Base").hide()
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
	player_instance.set_network_master(id)

func _on_training_b_pressed():
	Networking.create_server()
	Networking.server.refuse_new_connections = true
	instance_player(get_tree().get_network_unique_id())
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(training_map)
	ServerInfo.isMatchStart = true


func _on_spin_cap_value_changed(value):
	Networking.max_clients = value
	plr_cap.release_focus()
