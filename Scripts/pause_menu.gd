extends Control

onready var menu_b = $menu_b
onready var resume_b = $resume_b
onready var player = get_parent().get_parent().get_parent().get_parent().get_parent()

func _ready():
	if !ServerInfo.is_connected("matchOver", self, "_ready"):
# warning-ignore:return_value_discarded
		ServerInfo.connect("matchOver", self,"_ready")
	hide()

func _input(_event):
	if Input.is_action_just_pressed("ui_cancel") && ServerInfo.isMatchStart && player.isPlayer:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			hide()
		else:
			show()
		return

func _on_menu_b_pressed():
	var main_scene = Networking.main_menu
	if get_tree().is_network_server():
		rpc("shutdown_server")
	else:
		rpc("notify_plrs", get_tree().get_network_unique_id())
# warning-ignore:return_value_discarded
		get_tree().change_scene_to(main_scene)
		Networking.reset_server()

func _on_resume_b_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide();

sync func shutdown_server():
	var main_scene = Networking.main_menu
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(main_scene)
	Networking.reset_server()

sync func notify_plrs(id):
	Networking._player_disconnected(id)
