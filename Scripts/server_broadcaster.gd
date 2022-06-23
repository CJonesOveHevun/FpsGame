extends Node

export (float) var broadcast_interval = 1.0
var server_info = {"name" : "LAN Game"}

var socket_udp
var broadcast_timer = Timer.new()
var broadcast_port = Networking.default_port

func _enter_tree():
	broadcast_timer.wait_time = broadcast_interval
	broadcast_timer.one_shot = false
	broadcast_timer.autostart = true
	
	if get_tree().is_network_server():
		add_child(broadcast_timer)
		broadcast_timer.connect("timeout", self , "broadcast")
		
		socket_udp = PacketPeerUDP.new()
		socket_udp.set_broadcast_enabled(true)
		socket_udp.set_dest_address('255.255.255.255', broadcast_port)
		

func broadcast():
	server_info.name = Networking.ip_address
	var packet_msg = to_json(server_info)
	var packet = packet_msg.to_ascii()
	socket_udp.put_packet(packet)

func _exit_tree():
	broadcast_timer.stop()
	if socket_udp != null:
		socket_udp.close()

func _notification(what):
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		broadcast_timer.stop()
		if socket_udp != null:
			socket_udp.close()
			print("closing server")
	else:
		return
