extends Node

signal new_server
signal remove_server

var clean_up_timer = Timer.new()
var socket_udp = PacketPeerUDP.new()
var listen_port = Networking.default_port
var known_servers = {}

export (int) var server_cleanup_threshold = 1

func _init():
	clean_up_timer.wait_time = server_cleanup_threshold
	clean_up_timer.one_shot = false
	clean_up_timer.autostart = true
	clean_up_timer.connect("timeout", self, "clean_up")
	add_child(clean_up_timer)
	

func _ready():
	known_servers.clear()
	
	if socket_udp.listen(listen_port) != OK:
		print("GameServer LAN service : Error listening to port: "+ str(listen_port))
	else:
		print("GameServer LAN service : listening to port: " + str(listen_port))

func _process(_delta):
	if socket_udp.get_available_packet_count() > 0:
		var server_ip = socket_udp.get_packet_ip()
		var server_port = socket_udp.get_packet_port()
		var array_bytes = socket_udp.get_packet()
		
		if server_ip != "" && server_port > 0 && array_bytes.size() > 0:
			if not known_servers.has(server_ip) && server_ip != null:
				var serverMessage = array_bytes.get_string_from_ascii()
				if serverMessage == null:
					return
				var gameInfo = parse_json(serverMessage)
				if gameInfo == null:
					return
				gameInfo.ip = server_ip
				gameInfo.lastSeen = OS.get_unix_time()
				known_servers[server_ip] = gameInfo
				emit_signal("new_server", gameInfo)
			else:
				var gameInfo = known_servers[server_ip]
				gameInfo.lastSeen = OS.get_unix_time()
		else:
			return

func clean_up():
	var now = OS.get_unix_time()
	for server_ip in known_servers:
		var serverInfo = known_servers[server_ip]
		if (now - serverInfo.lastSeen > server_cleanup_threshold):
			known_servers.erase(server_ip)
			print('Remove old server: %s' % [server_ip])
			emit_signal("remove_server", server_ip)

func _exit_tree():
	socket_udp.close()
