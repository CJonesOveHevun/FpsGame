extends Control

onready var join_dir = $join_dir
onready var address_bar = $address_bar
onready var timer = $join_dir/connection_time
onready var server_container = $server_container
onready var join_local = $join_local

func _on_back_b_pressed():
	return get_tree().reload_current_scene()

func _on_Server_browser_new_server(gameInfo):
	var server_node = ServerInfo.instance_node(load("res://Scenes/Prefabs/server_display.tscn"), server_container)
	server_node.text = "Server by " + "%s - %s" % [gameInfo.username, gameInfo.ip]
	server_node.ip_address = gameInfo.ip
	pass

func _on_Server_browser_remove_server(serverIp):
	for serverNode in server_container.get_children():
		if serverNode.is_in_group("server"):
			if serverNode.ip_address == serverIp:
				serverNode.queue_free()
				break

func _on_join_dir_pressed():
	if address_bar.text != "":
		direct_join_ui(1)
		timer.start()
		Networking.ip_address = address_bar.text
		Networking.join_server()

func browser_disable():
	direct_join_ui(1)
	timer.start()

func direct_join_ui(toggle: int):
	if toggle == 1:
		join_dir.release_focus()
		address_bar.release_focus()
		join_local.disabled = true
		join_dir.disabled = true
		address_bar.editable = false
		server_container.hide()
		join_local.release_focus()
	elif toggle == 0:
		join_dir.release_focus()
		address_bar.grab_focus()
		join_local.release_focus()
		server_container.show()
		join_local.disabled = false
		join_dir.disabled = false
		address_bar.editable = true


func _on_connection_time_timeout():
	direct_join_ui(0)
	Networking.client = null
	print("ERR - client : connection failed/timeout!")




func _on_address_bar_text_entered(_new_text):
	_on_join_dir_pressed()


func _on_join_local_pressed():
	direct_join_ui(1)
	timer.start()
	Networking.ip_address = "127.0.0.1"
	Networking.join_server()
