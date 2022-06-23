extends Node

const default_port = 6969
const max_clients = 8

var server = null
var client = null

var ip_address = ""

onready var main_menu = preload("res://Scenes/Prefabs/Menu.tscn")
onready var server_browser = preload("res://Scenes/Prefabs/Server_browser.tscn")
onready var server_lobby = preload("res://Scenes/Prefabs/Lobby.tscn")


func _ready() -> void:
	if OS.get_name() == "Windows":
		ip_address = IP.get_local_addresses()[3]
	else:
		ip_address = IP.get_local_addresses()[3]
	
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and !ip.ends_with("1"):
			ip_address = ip
			
# warning-ignore:return_value_discarded
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("connected_to_server", self, "_connected_to_server")
# warning-ignore:return_value_discarded
	get_tree().connect("server_disconnected", self, "_server_disconnected")
# warning-ignore:return_value_discarded
	get_tree().connect("connection_failed", self, "_connection_failed")

func _player_disconnected(id):
	if Players.has_node(str(id)):
		Players.get_node(str(id)).queue_free()

func create_server() -> void:
	server = NetworkedMultiplayerENet.new()
	server.create_server(default_port, max_clients)
	get_tree().set_network_peer(server)
	server.transfer_mode = NetworkedMultiplayerPeer.TRANSFER_MODE_UNRELIABLE_ORDERED
	OS.set_window_title("FPS GAME - SERVER")

func join_server() -> void:
	client = NetworkedMultiplayerENet.new()
	client.create_client(ip_address, default_port)
	get_tree().set_network_peer(client)
	print(get_tree().network_peer.get_connection_status(), "connection")
	OS.set_window_title("FPS GAME - CLIENT")

func _connected_to_server() -> void:
	print("connected")

func _connection_failed():
	print("Connection failed!")
# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()
	reset_server()

func _server_disconnected():
	print("disconnected" + " :" + str(get_tree().get_network_connected_peers()))
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(main_menu)
	reset_server()

func reset_server():
	for i in Players.get_children():
		i.set_physics_process(false)
		i.set_process(false)
		i.queue_free()
	get_tree().network_peer = null
	if server != null : server = null;
	ServerInfo.isMatchStart = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
