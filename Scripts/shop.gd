extends Control

onready var b_back = $b_back
onready var b_buy = $buy_b
onready var category = $category
onready var vbox_cat = $weaponslist/VBoxContainer
onready var price_lbl = $price_lbl
onready var hgs = vbox_cat.find_node("hg")
onready var smgs = vbox_cat.find_node("smg")
onready var sgs = vbox_cat.find_node("sg")
onready var ars = vbox_cat.find_node("ar")

var selected_gun : String = ""
var plr

var gun_price = {"Glock17": 700, "Uzi": 1000, "Sawedoff": 900, "Wm1897": 1350,
"Ak47": 2500, "Vector": 850,"Revolver":1000, "M16": 2500, "Mp5": 1000}

func _ready():
# warning-ignore:return_value_discarded
	ServerInfo.connect("matchOver",self, "disable_shop")
	plr = get_parent()

func _process(_delta):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		call_deferred("queue_free")
	if !Input.is_mouse_button_pressed(BUTTON_LEFT):
		return
	for ct in category.get_children():
		if ct.pressed:
			ct.release_focus()
			hgs.visible = ct.name == "Hg"
			smgs.visible = ct.name == "Smg"
			sgs.visible = ct.name == "Sg"
			ars.visible = ct.name == "Ar"
	for guns in vbox_cat.get_children():
		for w in guns.get_children():
			if w.pressed:
				w.release_focus()
				selected_gun = w.text
				b_buy.visible = true
				price_lbl.text = "$" + str(gun_price[selected_gun]) + " Current: " + str(plr.money)

func _on_b_back_pressed():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	queue_free()

func disable_shop():
	queue_free()

func _on_buy_b_pressed():
	if plr != null:
		var money = plr.money
		if !money >= gun_price[selected_gun]:
			return
		else:
			plr.money -= gun_price[selected_gun]
			match WeaponsInfo.weapon_type[selected_gun]:
				WeaponsInfo.Handgun:
					plr.secondary_slot = selected_gun
				_:
					plr.primary_slot = selected_gun
			plr.add_new_gun(selected_gun)
			price_lbl.text = "Remaing: $" + str(plr.money)
