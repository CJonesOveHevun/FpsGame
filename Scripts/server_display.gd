extends Label

var ip_address

func _on_join_b_pressed():
	Networking.ip_address = ip_address
	Networking.join_server()
	find_parent("Server_browser").browser_disable()
