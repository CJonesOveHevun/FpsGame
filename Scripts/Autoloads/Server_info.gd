extends Node

signal matchOver

var match_fin = false
var isMatchStart = false
var tick_update
var ready = false

var dm_kill_limit : int = 15 # 15
var tm_score_limit : int = 5 # 5

var team_score = {
	"team 1":0,
	"team 2":0
}

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
	tick_update.wait_time = 0.028
	tick_update.name = "tick_update"
	tick_update.connect("timeout", self, "update_server")
	Server.add_child(tick_update)

func _physics_process(_delta):
	if isMatchStart && get_tree().is_network_server() && !match_fin:
		update_bullets()
		rpc("update_bullets")
	else:
		return

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
		update_plr()
		rpc("update_plr")
		rpc_unreliable("sync_server", dm_kill_limit, servertype, isMatchStart)

remotesync func sync_server(dm_score, type, isStart):
	dm_kill_limit = dm_score
	servertype = type
	isMatchStart = isStart

remote func update_plr():
	for plr in Players.get_children():
		plr.rpc("update_pos" , plr.translation, plr.rotation.y,
		 plr.anim_tree.get("parameters/stand_state/blend_amount"),
		 plr.anim_tree.get("parameters/isReloading/blend_amount"),
		 plr.anim_tree.get("parameters/sprint_spd/scale"),
		 plr.camera.rotation.x, plr.camera.rotation.x, plr.isCrouching, plr.username)

remote func update_bullets():
	for bl in get_tree().get_nodes_in_group("bullet"):
		if bl == null:
			return;
		bl.translation += bl.transform.basis.z * 0.1
		if bl.is_colliding():
			var point = bl.get_collision_point()
			var e = bl.get_collider()
			if e.get_parent() is KinematicBody && !e.get_parent().isDead:
				if servertype == 0 || servertype == 1 && !bl.is_in_group(str(e.get_parent().team)):
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
				bl.set_deferred("enabled", false)
				call_deferred("b_impact_async", point, bl)
			else:
				return

func b_impact_async(p, raycast):
	var i = b_impact.instance()
	Server.add_child(i, true)
	if raycast.get_collision_normal() == Vector3.UP:
		i.translation = p + raycast.get_collision_normal().normalized() / 10
		i.set_deferred("rotation_degrees.z", 90)
	elif raycast.get_collision_normal() == Vector3.DOWN:
		i.translation = p + raycast.get_collision_normal().normalized() / 10
		i.set_deferred("rotation_degrees.z", -90)
	else:
		i.translation = p
		i.call_deferred("look_at",  p + raycast.get_collision_normal(), Vector3.UP)

# warning-ignore:unused_argument
remote func dm_score_update(id, killerid):
	for i in Players.get_children():
		if i.name == str(killerid):
			if i.dm_kills >= dm_kill_limit:
				#rpc("reset_scores", i.username, i.team)
				reset_scores(i.username, i.team)

# warning-ignore:unused_argument
remote func tm_score_update(id, killerid):
	for i in Players.get_children():
		if i.name == str(killerid):
			#rpc("update_team_score", i.team)
			if team_score["team 1"] >= tm_score_limit:
				reset_scores(i.username, "Team 1")
			elif team_score["team 2"] >= tm_score_limit:
				#rpc("reset_scores", i.username, "Team 2")
				reset_scores(i.username, "Team 2")

sync func update_team_score(teamtype):
	var get_team : int = 0
	if Players.has_node(str(teamtype)):
		get_team = Players.get_node(str(teamtype)).team
	if get_team == 1:
		team_score["team 1"] += 1
		print(team_score)
		return
	team_score["team 2"] += 1
	print(team_score)

remote func instance_ragdoll(id, col):
	if Players.has_node(str(id)):
		var plrn = Players.get_node(str(id))
		var rg = ragdoll.instance()
		rg.get_node("character_fps/skeleton_game_rig/Skeleton/whole_body").get("material/0").albedo_color = col #color correction
		rg.translation = plrn.translation
		Server.call_deferred("add_child", rg, true)
		return

sync func add_score(killer):
	for i in Players.get_children():
		if i.name == str(killer):
			i.dm_kills += 1

sync func reset_scores(winnerid, team):
	var vote_map = preload("res://Scenes/Prefabs/vote_map.tscn")
	emit_signal("matchOver")
	for plr in Players.get_children():
		plr.dm_kills = 0
		plr.translation.y = -115
		plr.canMove = true
		plr.isDead = false
		plr.velo += Vector3(0.1,-5,0.1)
		match_fin = true
		if ServerInfo.servertype == 0:
			winner = winnerid;
		elif ServerInfo.servertype == 1:
			winner = team;
		yield(get_tree().create_timer(1),"timeout")
# warning-ignore:return_value_discarded
		ServerInfo.instance_node(vote_map, plr);
		team_score["team 1"] = 0
		team_score["team 2"] = 0
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
