extends Node

var models = {"Glock17": preload("res://Scenes/Characters/weapons/guns/glock17.tscn"),
"Uzi": preload("res://Scenes/Characters/weapons/guns/uzi.tscn"),
"Sawedoff":preload("res://Scenes/Characters/weapons/guns/sawedoff.tscn"),
"Wm1897":preload("res://Scenes/Characters/weapons/guns/wm1897.tscn"),
"Ak47":preload("res://Scenes/Characters/weapons/guns/ak47.tscn"),
"Vector":preload("res://Scenes/Characters/weapons/guns/vector.tscn"),
"Revolver":preload("res://Scenes/Characters/weapons/guns/revolver.tscn"),
"M16": preload("res://Scenes/Characters/weapons/guns/M16.tscn"),
"Mp5": preload("res://Scenes/Characters/weapons/guns/Mp5.tscn")}

var bullets = {"9mm": preload("res://Scenes/Characters/weapons/bullets/9mm.tscn"),
"762mm":preload("res://Scenes/Characters/weapons/bullets/762mm.tscn"),
"12gauge":preload("res://Scenes/Characters/weapons/bullets/12gauge.tscn"),
"556mm": preload("res://Scenes/Characters/weapons/bullets/556mm.tscn")}

enum {
	Handgun
	Shotgun
	Submachinegun
	Machinegun
	AssaultRifle
	SniperRifle
	BoltAction #crossbows & bows
	RPG
	Melee
}

var sg_reloadtype = {"Sawedoff": 0,"Wm1897":1}

var weapon_type = {"Glock17": Handgun, "Uzi":Submachinegun,"Sawedoff":Shotgun,
"Wm1897":Shotgun, "Ak47": AssaultRifle, "Vector": Submachinegun, "Revolver": Handgun,
"M16": AssaultRifle, "Mp5": Submachinegun}

var weapon_max_ammo = {"Glock17": 17, "Uzi": 32, "Sawedoff":2,
"Wm1897":8, "Ak47": 32, "Vector": 18, "Revolver": 6, "M16": 40, "Mp5": 30}

var weapon_ammo_pool = {"Glock17": 12, "Uzi": 7, "Sawedoff": 18,
"Wm1897":64, "Ak47" : 7, "Vector": 9, "Revolver": 12, "M16": 8, "Mp5": 7}

var weapon_firerate = {"Glock17": 0.1, "Uzi": 0.04,"Sawedoff":0.5,
"Wm1897":1.4, "Ak47": 0.1 ,"Vector": 0.07, "Revolver":0.8, "M16": 0.08, "Mp5": 0.07}

var weapon_recoil = {"Glock17": 4, "Uzi": 4,"Sawedoff":50,"Wm1897":70, "Ak47":12, "Vector":2,
"Revolver":8, "M16": 9, "Mp5": 3}

var bullet_dmg = {"9mm": round(rand_range(12,17)), "45acp":round(rand_range(19,28)),
"12gauge": round(rand_range(10,15)),"762mm":round(rand_range(25,36)),"556mm":round(rand_range(20,36))}

var ammo_use = {"Glock17": "9mm", "Uzi" : "9mm","Sawedoff":"12gauge","Wm1897":"12gauge",
"Ak47": "762mm", "Vector":"9mm", "Revolver":"762mm", "M16": "556mm", "Mp5": "9mm"}


###################################SOUND EFFECTS#####################################
onready var streams = {"Glock17": preload("res://Materials/Sfx/fpsgame-sounds_glock17_gun_fire.mp3"),
"Uzi":preload("res://Materials/Sfx/fpsgame-sounds_uzi_gun_fire.mp3"),
"Sawedoff":preload("res://Materials/Sfx/fpsgame-sounds_shotgun_gun_fire.mp3"),
"Revolver":preload("res://Materials/Sfx/fpsgame-sounds_shotgun_gun_fire.mp3"),
"Wm1897":preload("res://Materials/Sfx/fpsgame-sounds_shotgun_gun_fire.mp3"),
"Vector":preload("res://Materials/Sfx/fpsgame-sounds_uzi_gun_fire.mp3"),
"Mp5":preload("res://Materials/Sfx/fpsgame-sounds_uzi_gun_fire.mp3"),
"Ak47":preload("res://Materials/Sfx/fpsgame-sounds_ak_gun_fire.mp3"),
"M16":preload("res://Materials/Sfx/fpsgame-sounds_m4s_gun_fire.mp3")}

var pitch = {
	"Glock17": 1.28,
	"Uzi": 1.7,
	"Sawedoff": 1.0,
	"Revolver": 1.2,
	"Wm1897": 1.25,
	"Vector": 2.6,
	"Mp5": 1.2,
	"Ak47": 1.0,
	"M16": 1.0
	}

sync func emit_fire_sound(gun:String,pos: Vector3):
	var new_s = sfx_timeout.new()
	new_s.unit_db = 4
	new_s.unit_size = 2
	new_s.max_db = 5
	new_s.set_stream(streams[gun])
	new_s.pitch_scale = pitch[gun]
	new_s.translation = pos
	Server.add_child(new_s,true)
	new_s.play()
