extends Node

var models = {"Glock17": preload("res://Scenes/Characters/weapons/guns/glock17.tscn"),
"Uzi": preload("res://Scenes/Characters/weapons/guns/uzi.tscn"),
"Sawedoff":preload("res://Scenes/Characters/weapons/guns/sawedoff.tscn"),
"Wm1897":preload("res://Scenes/Characters/weapons/guns/wm1897.tscn"),
"Ak47":preload("res://Scenes/Characters/weapons/guns/ak47.tscn"),
"Vector":preload("res://Scenes/Characters/weapons/guns/vector.tscn"),
"Revolver":preload("res://Scenes/Characters/weapons/guns/revolver.tscn")}

var bullets = {"9mm": preload("res://Scenes/Characters/weapons/bullets/9mm.tscn"),
"762mm":preload("res://Scenes/Characters/weapons/bullets/762mm.tscn"),
"12gauge":preload("res://Scenes/Characters/weapons/bullets/12gauge.tscn")}

enum {
	Handgun
	Shotgun
	Submachinegun
	Machinegun
	AssualtRifle
	SniperRifle
	BoltAction #crossbows & bows
	RPG
	Melee
}
var sg_reloadtype = {"Sawedoff": 0,"Wm1897":1}

var weapon_type = {"Glock17": Handgun, "Uzi":Submachinegun,"Sawedoff":Shotgun,
"Wm1897":Shotgun, "Ak47": AssualtRifle, "Vector": Submachinegun, "Revolver": Handgun}

var weapon_max_ammo = {"Glock17": 17, "Uzi": 32, "Sawedoff":2,
"Wm1897":8, "Ak47": 40, "Vector": 18, "Revolver": 6}

var weapon_ammo_pool = {"Glock17": 12, "Uzi": 14, "Sawedoff": 21,
"Wm1897":64, "Ak47" : 10, "Vector": 14, "Revolver": 12}

var weapon_firerate = {"Glock17": 0.1, "Uzi": 0.05,"Sawedoff":0.5,
"Wm1897":1.8, "Ak47": 0.1 ,"Vector": 0.07, "Revolver":0.8}

var weapon_recoil = {"Glock17": 4, "Uzi": 4,"Sawedoff":50,"Wm1897":70, "Ak47":10, "Vector":2,
"Revolver":8}

var bullet_dmg = {"9mm": round(rand_range(14,23)), "45acp":round(rand_range(19,28)),
"12gauge": round(rand_range(7,12)),"762mm":round(rand_range(25,36)),"556mm":round(rand_range(20,36))}

var ammo_use = {"Glock17": "9mm", "Uzi" : "9mm","Sawedoff":"12gauge","Wm1897":"12gauge",
"Ak47": "762mm", "Vector":"9mm", "Revolver":"762mm"}
