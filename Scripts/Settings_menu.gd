extends Control

onready var menu = load("res://Scenes/Prefabs/Menu.tscn")
onready var m_slider = $tabcont/Controls/Mouse/sensitivity
onready var line_name = $tabcont/Profile/usrname_lbl/line_name
onready var feedback = $tabcont/Profile/usrname_lbl/feedback
onready var fullscreen = $tabcont/Video_Settings/lblgeometry/fullsreen_check
onready var vp_mode = $tabcont/Video_Settings/stretchmode/viewport_stretch
onready var lod_slider = $tabcont/Video_Settings/lod_dist_lbl/lod_dist

func _on_menu_b_pressed():
	return get_tree().change_scene_to(menu)

func _ready():
	line_name.text = Settings.username
	m_slider.value = Settings.mouse_sensitivty
	fullscreen.pressed = Settings.isFullscreen
	vp_mode.pressed = Settings.viewportmode
	lod_slider.value = Settings.lod_distance

func _on_Button_pressed():
	print("Coming soon")


func _on_sensitivity_value_changed(value):
	Settings.mouse_sensitivty = value


func _on_line_name_text_entered(new_text):
	Settings.username = new_text
	feedback.text = "Saved!"
	feedback.visible = true
	line_name.release_focus()


func _on_line_name_text_changed(_new_text):
	feedback.text = "Not saved!"
	feedback.visible = true


func _on_fullsreen_check_toggled(button_pressed):
	Settings.isFullscreen = button_pressed;
	OS.window_fullscreen = button_pressed;
	return


func _on_CheckBox_toggled(button_pressed):
	if button_pressed:
		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_IGNORE, Vector2(1024,600))
		Settings.viewportmode = true
	else:
		get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED, SceneTree.STRETCH_ASPECT_IGNORE, Vector2(1024,600))
		Settings.viewportmode = false


func _on_lod_dist_value_changed(value):
	Settings.lod_distance = value
