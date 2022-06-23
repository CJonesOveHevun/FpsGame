extends Control

onready var join_dir = $join_dir
onready var address_bar = $address_bar
onready var timer = $join_dir/connection_time
onready var server_container = $server_container

func _on_back_b_pressed():
	return get_tree().reload_current_scene()

func _on_Server_browser_new_server(gameInfo):
	var server_node = ServerInfo.instance_node(load("res://autoloads/server_display.tscn"), server_container)
	server_node.text = "Server" + "%s - %s" % [gameInfo.name, gameInfo.ip]
	server_node.ip_address = str(gameInfo.ip)
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
		join_dir.disabled = true
		address_bar.editable = false
		server_container.hide()
	elif toggle == 0:
		join_dir.release_focus()
		address_bar.release_focus()
		server_container.show()
		join_dir.disabled = false
		address_bar.editable = true


func _on_connection_time_timeout():
	direct_join_ui(0)
	Networking.client = null
	print("ERR - client : connection failed/timeout!")


