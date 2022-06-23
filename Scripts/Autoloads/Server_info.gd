extends Node


var isMatchStart = false
var tick_update
var ready = false


enum {
	TRAINING
	DEATHMATCH
	TEAMMATCH
	SNIPER
};
onready var player = preload("res://Scenes/Characters/player.tscn")
onready var effects = {"blood_ex":preload("res://Scenes/effects/blood_explode.tscn")}
onready var shop_module = preload("res://Scenes/Prefabs/shop.tscn")
onready var respawn_timer = preload("res://Scenes/Prefabs/respawn_timer_ui.tscn")
var servertype = DEATHMATCH;

func _ready():
	tick_update = Timer.new()
	tick_update.autostart = true
	tick_update.wait_time = 0.025
	tick_update.name = "tick_update"
	tick_update.connect("timeout", self, "update_server")
	Server.add_child(tick_update)

func _physics_process(_delta):
	if isMatchStart && get_tree().is_network_server():
		rpc("update_bullets")

func instance_node_location(node: Object,parent: Object, location: Vector3)-> Object:
	var node_instance = instance_node(node, parent)
	node_instance.global_transform.origin = location
	return node_instance

func instance_node(node: Object, parent: Object) -> Object:
	var node_instance = node.instance()
	parent.add_child(node_instance)
	return node_instance

func update_server():
	if get_tree().is_network_server():
		rpc("update_plr")
	else:
		return

remotesync func update_plr():
	for plr in Players.get_children():
		plr.rpc("update_pos" , plr.translation, plr.rotation.y,
		 plr.anim_tree.get("parameters/walk_idle/blend_amount"),
		 plr.anim_tree.get("parameters/is_reloading/blend_amount"),
		 plr.anim_tree.get("parameters/sprinting_int/scale"),
		 plr.camera.rotation.x, plr.camera.rotation.x)

sync func update_bullets():
	for bl in get_tree().get_nodes_in_group("bullet"):
		bl.cast_to += Vector3(0,0,5)
		bl.translation += bl.transform.basis.z * 0.2
		if bl.is_colliding():
			var e = bl.get_collider()
			if e.get_parent() is KinematicBody && !e.get_parent().isDead:
				if !bl.name.begins_with(e.get_parent().name +"b"):
					bl.force_raycast_update()
					if e.name.ends_with("torso"):
						e.get_parent().rpc("plr_hurt", bl.name.rstrip("0123456789"))
						bl.enabled = false
						bl.queue_free()
					if e.name.ends_with("head"):
						e.get_parent().rpc("plr_hurt", bl.name.rstrip("0123456789"), true)
						bl.enabled = false
						bl.queue_free()
			else:
				return


sync func dm_score_update(id, killerid):
	print(id," got killed!")
	for i in Players.get_children():
		if i.name == str(killerid):
			i.gain_money()
