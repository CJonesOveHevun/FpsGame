extends Node

signal matchOver

var match_fin = false
var isMatchStart = false
var tick_update
var ready = false

var dm_kill_limit : int = 15 # 15

var winner = ""

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
onready var b_impact = preload("res://Scenes/effects/bullet_impact.tscn")
onready var ragdoll = preload("res://Scenes/effects/ragdoll.tscn")
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
	if !get_tree().is_network_server():
		return
	else:
		rpc("update_plr")
		rpc("sync_server", dm_kill_limit, servertype, isMatchStart)

sync func sync_server(dm_score, type, isStart):
	dm_kill_limit = dm_score
	servertype = type
	isMatchStart = isStart

remotesync func update_plr():
	for plr in Players.get_children():
		plr.rpc("update_pos" , plr.translation, plr.rotation.y,
		 plr.anim_tree.get("parameters/stand_state/blend_amount"),
		 plr.anim_tree.get("parameters/isReloading/blend_amount"),
		 plr.anim_tree.get("parameters/sprint_spd/scale"),
		 plr.camera.rotation.x, plr.camera.rotation.x, plr.isCrouching)

sync func update_bullets():
	for bl in get_tree().get_nodes_in_group("bullet"):
		bl.translation += bl.transform.basis.z * 0.1
		if bl.is_colliding():
			var point = bl.get_collision_point()
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
			elif !e.get_parent() is KinematicBody:
# warning-ignore:return_value_discarded
				instance_node_location(b_impact,get_tree().current_scene,point)
			else:
				return

remote func dm_score_update(id, killerid):
	for i in Players.get_children():
		if i.name == str(killerid):
			i.gain_money()
			rpc("add_score", killerid)
			if i.dm_kills >= dm_kill_limit:
				rpc("reset_scores", killerid)
	rpc("instance_ragdoll", id)

sync func instance_ragdoll(id):
	for i in Players.get_children():
		if i.name == str(id):
# warning-ignore:return_value_discarded
			instance_node_location(ragdoll, get_tree().current_scene, i.translation)

sync func add_score(killer):
	for i in Players.get_children():
		if i.name == str(killer):
			i.dm_kills += 1

sync func reset_scores(winnerid):
	var vote_map = preload("res://Scenes/Prefabs/vote_map.tscn")
	emit_signal("matchOver")
	for plr in Players.get_children():
		plr.dm_kills = 0
		plr.translation.y = -115
		plr.canMove = true
		plr.isDead = false
		plr.velo += Vector3(0.1,-5,0.1)
		match_fin = true
		winner = str(winnerid)
		yield(get_tree().create_timer(1),"timeout")
# warning-ignore:return_value_discarded
		ServerInfo.instance_node(vote_map, plr);
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
