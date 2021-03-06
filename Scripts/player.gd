extends KinematicBody

var username : String = ""
#####inventory#####
var primary_slot : String = ""
var secondary_slot : String = "M1911"
var equipment_slot : String = ""

var current_gun = secondary_slot
##################
onready var torso_hb = $torso_hitbox
onready var head_hb =$head_hitbox
#=======================
onready var primary_lbl = $camera/model_view/gui/primary_label
onready var secondary_lbl = $camera/model_view/gui/secondary_label
onready var ik_target = $camera/Ik_target
onready var skeletonik = $character_fps/skeleton_game_rig/Skeleton/SkeletonIK
onready var model_weapon_pos = $camera/Ik_target/model_weapon_pos
onready var model = $character_fps

onready var plr_color = $character_fps/skeleton_game_rig/Skeleton/whole_body
var skin_color = Settings.plr_color

onready var camera = $camera
onready var gui = $camera/model_view/gui
onready var usr_lbl = $camera/model_view/gui/usrname
onready var plr = self

onready var animation = $animation
onready var bound_box = $Bounding_box
onready var model_pos = $camera/model_view/model_pos
onready var bullet_pos = $camera/bullet_pos
onready var player_model = $character_fps
onready var pickupRay = $camera/pickup_ray
onready var jBuffer = $jumpbuffer
onready var fire_rate_cd = $fire_rate_cd

onready var hurt_hud = $camera/model_view/gui/injure_hud
onready var hp_bar = $camera/model_view/gui/health_bar
#=======================
##########################
onready var anim_tree = $anim_tree
##########################
###KILLS###
var dm_kills : int = 0

###TEAM###
var team : int = 0
###########
onready var s_gun = WeaponsInfo.models.M1911.instance()

export var health : int = 100
export var speed = 500
export var def_speed = 500
export var money = 1000

var velo = Vector3()
var gravity = Vector3()
export var weight = 5.6

var isPlayer = false
var canFire = true
var canReload = true
var stored_fall_damge : int = 0

var canMove = true
var is_ads = false
var is_sprinting = false
var isDead = false
var isCrouching = false
##ammo counter##
var current_ammo1 : int = WeaponsInfo.weapon_max_ammo[current_gun]
var current_ammo2 : int = WeaponsInfo.weapon_max_ammo[current_gun]

var ammo_pool1: int = WeaponsInfo.weapon_ammo_pool[current_gun]
var ammo_pool2: int = WeaponsInfo.weapon_ammo_pool[current_gun]
################

func _ready():
	s_gun.get_node("CollisionShape").disabled = true
	s_gun.set_mode(1)
	model_pos.add_child(s_gun, true)
	skeletonik.start()
	plr_color.get("material/0").albedo_color = Settings.plr_color
	_update_ammo()

remotesync func _set_name():
	if is_network_master():
		username = Settings.username

func _process(_delta):
	model_weapon_pos.visible = player_model.visible
	usr_lbl.text = username
	if is_network_master() && get_tree().network_peer != null:
		if ServerInfo.isMatchStart && !isDead && !ServerInfo.match_fin:
			shop()
			animate_model();
			ads()
			call_deferred("fov_update");
			weapon_fire(current_gun);
			show_leaderboards()
			if Input.is_action_just_pressed("reload") && !isDead:
				if ammo_pool1 > 0 && current_gun == primary_slot|| ammo_pool2 > 0 && current_gun == secondary_slot:
					reload_anim()
		plr_color.get("material/0").albedo_color = skin_color
		rpc_unreliable("set_skin_clr", skin_color)
	else:
		return

func _physics_process(delta):
	if get_tree().network_peer == null:
		return
	if is_network_master() && get_tree().network_peer != null:
		if ServerInfo.isMatchStart && !isDead:
			movement(delta)
			gravity_fall(delta)
			torso_hb.set_deferred("name" , str(plr.name) + "torso")
			head_hb.set_deferred( "name" , str(plr.name) + "head")
		if health > 35:
			hurt_hud.modulate.a = lerp(hurt_hud.modulate.a, 1 - (health * 0.01), 0.1)
		call_deferred("lod_to_distance") #calling to cull objects

remote func set_skin_clr(clr):
	plr_color.get("material/0").albedo_color = clr

func movement(delta):
	if canMove:
		velo.y = 0
		if is_on_floor() && jBuffer.is_stopped() && !ServerInfo.match_fin:
			velo = Vector3.ZERO if is_on_floor() else (velo * 1.2)
		if !ServerInfo.match_fin:
			if Input.is_action_pressed("w"):
				velo += transform.basis.z * speed
			if Input.is_action_pressed("s"):
				velo -= transform.basis.z * speed
			if Input.is_action_pressed("d"):
				velo -= transform.basis.x * speed
			if Input.is_action_pressed("a"):
				velo += transform.basis.x * speed
			if Input.is_action_just_pressed("jump"):
				jBuffer.start()
			
			if (!jBuffer.is_stopped() && is_on_floor()):
				gravity.y = 14
				velo.y = 1
			if Input.is_action_pressed("crouch"):
				bound_box.scale.y = 0.7
				bound_box.translation.y = lerp(bound_box.translation.y,0.711, 0.6)
				isCrouching = true
			else:
				bound_box.scale.y = lerp(bound_box.scale.y,1, 0.1)
				bound_box.translation.y = lerp(bound_box.translation.y, 0.129, 0.1)
				isCrouching = false
		cam_shake(0.05, 0.5, delta)
		velo = velo.normalized()
		velo = move_and_slide(velo * delta * speed, Vector3.UP, true)
	else:
		return;

func cam_shake(amplitude, freq, time):
	var it : float = 0
	it += time
	var wave = amplitude * sin(it * speed * freq)
	if velo != Vector3.ZERO: #camera shake
		time += time
		camera.v_offset = lerp(camera.v_offset, wave, 0.1) #lerp(camera.v_offset,cos(time * freq) * amplitude,0.1)
	else:
		time = 0
		camera.v_offset = lerp(camera.v_offset,0, 0.1)
	
func gravity_fall(delta):
	if canMove:
		if !is_on_floor():
			velo.x = velo.x * 1.1
			velo.z = velo.z * 1.1
			gravity.y -= sqrt(delta + weight) * 0.3
			gravity = move_and_slide(gravity, Vector3.UP, true)
			if jBuffer.is_stopped():
				if gravity.y <= -50 && !ServerInfo.match_fin:
					stored_fall_damge += int(gravity.y * 0.1)
		elif is_on_floor() && jBuffer.is_stopped():
			velo = Vector3(0,0,0)
			gravity = move_and_slide_with_snap(gravity,Vector3(0,-5,0), Vector3.UP, true)
			gravity = Vector3.ZERO
			if stored_fall_damge != 0:
				health += stored_fall_damge
				stored_fall_damge = 0
				update_stats(health, null)
				injure_feedback()

func _input(event):
	if get_tree().network_peer == null:
		return
	if is_network_master() && ServerInfo.isMatchStart && get_tree().network_peer != null:
		if !is_ads && !isDead && !Input.is_action_pressed("fire"):
			switch_gun()
		if canReload:
			_interact()
		if Input.is_action_just_pressed("ui_cancel"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			elif Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event is InputEventMouseMotion && is_network_master() && get_tree().network_peer != null:
		if ServerInfo.isMatchStart && !isDead:
			gui.set_deferred("visible" ,true) # load player gui
		model_pos.visible = true if !isDead else false;
		player_model.set_deferred("visible" , false)# unload plr model
		camera.current = true#set camera
		isPlayer = true#check if puppet or not
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			camera.rotate_x(deg2rad(event.relative.y * Settings.mouse_sensitivty))#X rotation of camera
			rotate_y(deg2rad(-event.relative.x * Settings.mouse_sensitivty))#rotaion of plr
			camera.rotation.x = clamp(camera.rotation.x,deg2rad(-89),deg2rad(89))#limit rotation degrees
			camera.rotation.y = deg2rad(180)
			camera.rotation.z = 0
			ik_target.rotation.x = camera.rotation.x # rotate the body of plr relative to cameraX
			var drag_event = -event.relative.x
			var w_model = $camera/model_view
			if drag_event > 5: #below here is weapon sway system
				w_model.rotation_degrees.z = lerp_angle(w_model.rotation_degrees.z, 5, 0.1)
			elif drag_event < -5:
				w_model.rotation_degrees.z = lerp_angle(w_model.rotation_degrees.z, -5, 0.1)
			else:
				w_model.rotation_degrees.z = lerp_angle(w_model.rotation_degrees.z, 0, 0.1)
		call_deferred("_update_ammo")
	else:
		return
##############AMMO###################
func _update_ammo():
	if current_gun == secondary_slot && secondary_slot != "":
		secondary_lbl.text = "%s - %s : %s" % [secondary_slot, str(current_ammo2), str(ammo_pool2)]
	elif secondary_slot == "":
		secondary_lbl.text = "Secondary"
	if current_gun == primary_slot && primary_slot != "":
		primary_lbl.text = "%s - %s : %s" % [primary_slot, str(current_ammo1), str(ammo_pool1)]
	elif primary_slot == "":
		primary_lbl.text = "Primary"
	fire_rate_cd.wait_time = WeaponsInfo.weapon_firerate[current_gun]
####################################
func ads():
	if !is_sprinting:
		if Input.is_action_just_pressed("aim") && canReload:
			animation.play("ads")
			is_ads = true
		elif Input.is_action_just_released("aim") && is_ads:
			animation.play_backwards("ads")
			is_ads = false
		if is_ads || !canReload || isCrouching:
			speed = def_speed * 0.5
		else:
			speed = def_speed
	#sprinting
	if canReload:
		if Input.is_action_just_pressed("sprint") && !is_ads && !isCrouching:
			animation.play("sprint")
			speed = def_speed * 1.5
			is_ads = false
			is_sprinting = true
		elif Input.is_action_just_released("sprint") && !is_ads && is_sprinting:
			animation.play_backwards("sprint")
			speed = def_speed
			is_ads = false

func weapon_fire(gun:String):
	#recoil
	var magnitude = Vector3()
	var recoil_rate = WeaponsInfo.weapon_recoil[gun]
	var withdraw: float = 1
	if Input.is_action_pressed("fire") && canFire && !is_sprinting && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if current_gun == primary_slot && current_ammo1 > 0 || current_gun == secondary_slot && current_ammo2 > 0:
			withdraw += 0.1
			camera.fov += 4
			rpc("instance_bullets",WeaponsInfo.ammo_use[gun])
			WeaponsInfo.rpc_unreliable("emit_fire_sound",current_gun,translation)
			#for guns to animate itself, it must be named anim.
			model_pos.get_child(0).get_node("anim").play("fire")
			fire_rate_cd.start()
			canReload = false
			canFire = false
			#add magnitude
			magnitude = Vector3(camera.rotation_degrees.x + withdraw,(rotation_degrees.y * rand_range(-withdraw, withdraw) * 0.5),0)
			#horizontal recoil
			rotation_degrees.y = lerp_angle(rotation_degrees.y , magnitude.y * recoil_rate, 0.5)
			#vertical recoil
			camera.rotation_degrees.x = lerp_angle(camera.rotation_degrees.x,magnitude.x,0.5)
			#limit the rcoil to avoid bugs
			camera.rotation.x = clamp(camera.rotation.x,deg2rad(-89),deg2rad(89))
			camera.rotation.y = deg2rad(180)
			camera.rotation.z = 0
			match current_gun:
				primary_slot:
					if current_ammo1 > 0:
						current_ammo1 -= 1
				secondary_slot:
					if current_ammo2 > 0:
						current_ammo2 -= 1
			
			_update_ammo()
		elif current_gun == primary_slot && current_ammo1 <= 0 || current_gun == secondary_slot && current_ammo2 <= 0:
			if ammo_pool1 > 0 && current_gun == primary_slot or ammo_pool2 > 0 && current_gun == secondary_slot:
				anim_tree.set("parameters/isReloading/blend_amount", 1)
				reload_anim()
				withdraw = 1
				magnitude = Vector3.ZERO
	elif Input.is_action_just_released("fire") && canFire && !is_sprinting:
			withdraw = 1
			magnitude = Vector3.ZERO
	else:
		return

func reload_anim():
	var gun_reloadable = false
	if canReload && !is_sprinting:
		match current_gun: # a switch condition to determine what weapon needs a reload
			primary_slot: #if current gun is primary and the ammo is not max with the current gun!
				if current_ammo1 != WeaponsInfo.weapon_max_ammo[current_gun]:
					gun_reloadable = true
			secondary_slot:
				if current_ammo2 != WeaponsInfo.weapon_max_ammo[current_gun]:
					gun_reloadable = true
		if !model_pos.get_child(0).get_node("anim").is_connected("animation_finished", self, "_on_anim_finished"):
			model_pos.get_child(0).get_node("anim").connect("animation_finished",self ,"_on_anim_finished")
		if !gun_reloadable:
			return
		else:
			model_pos.get_child(0).get_node("anim").play("reload")
			canReload = false
			canFire = false
			if is_ads:
				animation.play_backwards("ads")
				is_ads = !animation.is_playing();

func fov_update():
	if is_ads:
		camera.fov = lerp(camera.fov, WeaponsInfo.weapon_fov[current_gun], 0.5)
	else:
		camera.fov = lerp(camera.fov, 80, 0.5)
	if is_sprinting:
		camera.fov = lerp(camera.fov, 95, 0.3)
	else:
		camera.fov = lerp(camera.fov, 80, 0.3)

###########
remote func update_pos(pos : Vector3, rot : float,
 w:float, r:float, s:float,
 ik: float, camx: float, isc : bool, usr: String):
	if camera.current:
		return
	else:
		camera.rotation.x = camx
		ik_target.rotation.x = deg2rad(ik)
		translation = pos
		rotation.y = lerp_angle(rotation.y, rot, 0.7)
		if w ==1: ## to consider the puppet
			anim_tree.set("parameters/crouch_state/blend_amount", 1)
			anim_tree.set("parameters/stand_state/blend_amount", 1)
		else:
			anim_tree.set("parameters/crouch_state/blend_amount", 0)
			anim_tree.set("parameters/stand_state/blend_amount", 0)
		if r ==1:
			anim_tree.set("parameters/isReloading/blend_amount", 1)
		else:
			anim_tree.set("parameters/isReloading/blend_amount", 0)
		if s == 1.7:
			anim_tree.set("parameters/sprint_spd/scale", 1.7)
		else:
			anim_tree.set("parameters/sprint_spd/scale", 1.3)
		if isc:
			anim_tree.set("parameters/is_crouching/blend_amount", 1)
		else:
			anim_tree.set("parameters/is_crouching/blend_amount", 0)
		if usr != "":
			username = usr

remote func onDeath():
	isDead = true
	canMove = false
	is_ads = false
	is_sprinting = false
	model_pos.visible = false
	model.visible = false
	animation.play_backwards("sprint")
	torso_hb.get_child(0).set_deferred("disabled" , true)
	head_hb.get_child(0).set_deferred("disabled" , true)
# warning-ignore:return_value_discarded
	ServerInfo.call_deferred("instance_node",ServerInfo.effects["blood_ex"],self)
# warning-ignore:return_value_discarded
	ServerInfo.instance_node(ServerInfo.respawn_timer, self)
	ServerInfo.instance_ragdoll(name, plr_color.get("material/0").albedo_color)

func gain_money():
	money += 350
	injure_feedback()
	

remote func update_weapon_model(gun):
	for i in model_weapon_pos.get_children():
		i.queue_free()

	var new_gun = WeaponsInfo.models[gun].instance()
	new_gun.set_mode(1)
	new_gun.get_node("CollisionShape").disabled = true
	model_weapon_pos.call_deferred("add_child", new_gun, true)
###########

func _on_fire_rate_cd_timeout():
	canFire = true
	canReload = true

func _on_anim_finished(anim):
	match anim:
		"sprint":
			if !Input.is_action_pressed("sprint"):
				is_sprinting = false
				is_ads = is_sprinting
		"reload":
			canFire = true
			canReload = true
			anim_tree.set("parameters/isReloading/blend_amount", 0)
			match current_gun:
				primary_slot:
					if ammo_pool1 > 0:
						if WeaponsInfo.weapon_type[current_gun] != WeaponsInfo.Shotgun:
							current_ammo1 = WeaponsInfo.weapon_max_ammo[current_gun]
							ammo_pool1 -= 1
						else:
							if current_ammo1 < WeaponsInfo.weapon_max_ammo[current_gun] && WeaponsInfo.sg_reloadtype[current_gun] == 1:
								current_ammo1 += 1
								ammo_pool1 -= 1
								reload_anim()
							else:
								current_ammo1 = WeaponsInfo.weapon_max_ammo[current_gun]
								ammo_pool1 -= 1
				secondary_slot:
					if ammo_pool2 > 0:
						current_ammo2 = WeaponsInfo.weapon_max_ammo[current_gun]
						ammo_pool2 -= 1
			_update_ammo()
		"holster":
			canFire = true
			canReload = true

func switch_gun():
	if Input.is_action_just_pressed("primary") && primary_slot != "" && current_gun != primary_slot:
		current_gun = primary_slot
		instance_weapons(primary_slot)
		canReload = false
		canFire = false
	elif Input.is_action_just_pressed("secondary") && secondary_slot != "" && current_gun != secondary_slot:
		current_gun = secondary_slot
		instance_weapons(secondary_slot)
		canReload = false
		canFire = false
	_update_ammo()

func instance_weapons(gun:String):
	#viewmodel
	var new_model = WeaponsInfo.models[gun].instance()
	new_model.set_mode(1)
	for e in model_pos.get_children():
		e.queue_free()
	for i in new_model.get_children():
		if i is CollisionShape:
			i.disabled = true
	model_pos.add_child(new_model, true)
	fire_rate_cd.wait_time = WeaponsInfo.weapon_firerate[gun]
	if !new_model.get_node("anim").is_connected("animation_finished", self, "_on_anim_finished"):
		new_model.get_node("anim").connect("animation_finished",self ,"_on_anim_finished")
		new_model.get_node("anim").play("holster")
	rpc("update_weapon_model", gun)

func _interact():
	if Input.is_action_just_pressed("interact"):
		if pickupRay.is_colliding():
			var get_collision = pickupRay.get_collider()
			add_new_gun(get_collision.name)
		else:
			return

onready var ldboard = $camera/model_view/gui/leaderboards

func show_leaderboards():
	ldboard.hide()
	if ServerInfo.servertype == 0:
		ldboard.visible = Input.is_action_pressed("tab") && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

func add_new_gun(gun:String):
	if canReload && !is_ads && !is_sprinting:
		match WeaponsInfo.weapon_type[gun]:
			WeaponsInfo.Handgun:
				secondary_slot = gun
				current_gun = secondary_slot
				ammo_pool2 = WeaponsInfo.weapon_ammo_pool[gun]
				current_ammo2 = WeaponsInfo.weapon_max_ammo[gun]
				instance_weapons(gun)
			WeaponsInfo.Melee:
				secondary_slot = gun
				current_gun = secondary_slot
				ammo_pool2 = WeaponsInfo.weapon_ammo_pool[gun]
				current_ammo2 = WeaponsInfo.weapon_max_ammo[gun]
				instance_weapons(gun)
			_:
				primary_slot = gun
				current_gun = primary_slot
				ammo_pool1 = WeaponsInfo.weapon_ammo_pool[gun]
				current_ammo1 = WeaponsInfo.weapon_max_ammo[gun]
				instance_weapons(gun)
		_update_ammo()

remotesync func animate_model():
	if !camera.current:
		return
	else:
		if Input.is_action_pressed("w")||Input.is_action_pressed("a")||Input.is_action_pressed("s")||Input.is_action_pressed("d"):
			anim_tree.set("parameters/crouch_state/blend_amount", 1)
			anim_tree.set("parameters/stand_state/blend_amount", 1)
		else:
			anim_tree.set("parameters/crouch_state/blend_amount", 0)
			anim_tree.set("parameters/stand_state/blend_amount", 0)
			
		if Input.is_action_just_pressed("reload") && canReload:
			anim_tree.set("parameters/isReloading/blend_amount", 1)
		else:
			pass
		if is_sprinting:
			anim_tree.set("parameters/sprint_spd/scale", 1.7)
		else:
			anim_tree.set("parameters/sprint_spd/scale", 1.3)
		if isCrouching:
			anim_tree.set("parameters/is_crouching/blend_amount", 1)
		else:
			anim_tree.set("parameters/is_crouching/blend_amount", 0)

sync func instance_bullets(type):
	var new_b = WeaponsInfo.bullets[type].instance()
	match type:
		"12gauge":
			for _i in range(1,12):
				var s = WeaponsInfo.bullets[type].instance()
				s.rotation.y = camera.rotation.y + deg2rad(rand_range(-4.5,4.5))
				s.rotation.x += deg2rad(rand_range(-4.0,4.0))
				s.name = str(plr.name) + "b" + str(type)
				s.translation = bullet_pos.translation
				s.translation.y += rand_range(-0.01,0.01)
				s.translation.x += rand_range(-0.01,0.01)
				bullet_pos.call_deferred("add_child", s, true)
				s.set_as_toplevel(true)
				if ServerInfo.servertype == 1:
					s.add_to_group(str(plr.team))
		_:
			new_b.rotation.y = camera.rotation.y
			new_b.translation = bullet_pos.translation
			new_b.name = str(plr.name) + "b" + str(type)
			bullet_pos.call_deferred("add_child", new_b, true)
			new_b.set_as_toplevel(true)
			if ServerInfo.servertype == 1:
				new_b.add_to_group(str(plr.team))

func _on_torso_hitbox_area_entered(area):
	if area.is_in_group("bullet") && !area.name.begins_with(name +"b"):
		area.get_parent().hide()
		print("hit!")

func _on_torso_hitbox_body_entered(body):
	if body.is_in_group("bullet"):
		print("hit")

sync func plr_hurt(bullet, ishead: bool=false):
	var hitter
	if !bullet.begins_with(name +"b") && bullet != "":
		randomize()
		if "9mm" in bullet:
			health -= WeaponsInfo.bullet_dmg["9mm"] * (2 if ishead else 1)
			hitter = bullet.trim_suffix("b9mm")
		if "12gauge" in bullet:
			health -= WeaponsInfo.bullet_dmg["12gauge"] * (2 if ishead else 1)
			hitter = bullet.trim_suffix("b12gauge")
		if "762mm" in bullet:
			health -= WeaponsInfo.bullet_dmg["762mm"] * (2 if ishead else 1)
			hitter = bullet.trim_suffix("b762mm")
		if "556mm" in bullet:
			health -= WeaponsInfo.bullet_dmg["556mm"] * (2 if ishead else 1)
			hitter = bullet.trim_suffix("b556mm")
		if "45acp"in bullet:
			health -= WeaponsInfo.bullet_dmg["45acp"] * (2 if ishead else 1)
			hitter = bullet.trim_suffix("b45acp")
		update_stats(health,hitter)
		injure_feedback()

func injure_feedback():
	hurt_hud.modulate.a = lerp(hurt_hud.modulate.a , 1, 0.7)
	speed = def_speed * 0.5

func update_stats(current_hp: float, hitter=""):
	hp_bar.value = current_hp
	if health <= 0 && !isDead:
		onDeath()
		if ServerInfo.servertype == 0:
			ServerInfo.add_score(int(hitter))
			ServerInfo.dm_score_update(int(name),int(hitter))
			ServerInfo.rpc("dm_score_update", int(name), int(hitter))
			for i in Players.get_children():
				if i.name == hitter:
					i.gain_money()
					return
		elif ServerInfo.servertype == 1:
			ServerInfo.update_team_score(int(hitter))
			ServerInfo.dm_score_update(int(name),int(hitter))
			ServerInfo.rpc("dm_score_update", int(name), int(hitter))
			for i in Players.get_children():
				if i.name == hitter:
					i.gain_money()
					return

func lod_to_distance()-> void:
	var root_camera = get_viewport().get_camera()
	var get_nodes
	var distance
	for e in get_tree().get_nodes_in_group("lod"):
		get_nodes = e
		distance = root_camera.global_transform.origin.distance_to(get_nodes.global_transform.origin)
		e.set_deferred("visible", distance < Settings.lod_distance);
		if e == null:
			break
			return

sync func respawn(type):
	var invi = preload("res://Scenes/effects/invincibilty.tscn").instance()
	match type:
		0:#deathmatch
			translation = Vector3(rand_range(-10,10), 0, rand_range(-10,10));
			health = 100
		1:#teammatch
			health = 100
			if team == 1:
				for i in get_tree().get_nodes_in_group("team1pos"):
					translation = i.translation
			elif team ==2:
				for y in get_tree().get_nodes_in_group("team2pos"):
					translation = y.translation

		_:
			pass;
	isDead = false;
	canMove = true;
	is_ads = false;
	is_sprinting = false;
	model_pos.visible = true if is_network_master() else false;
	model.visible = false if is_network_master() else true;
	if primary_slot != "":
		current_ammo1 = WeaponsInfo.weapon_max_ammo[primary_slot]
		ammo_pool1 = WeaponsInfo.weapon_ammo_pool[primary_slot]
	if secondary_slot != "":
		current_ammo2 = WeaponsInfo.weapon_max_ammo[secondary_slot]
		ammo_pool2 = WeaponsInfo.weapon_ammo_pool[secondary_slot]
	add_child(invi, true)
	animation.play_backwards("ads")
	update_stats(health);
	yield(get_tree().create_timer(5),"timeout")
	torso_hb.get_child(0).disabled = false;
	head_hb.get_child(0).disabled = false;

func shop():
	if ServerInfo.servertype == 0 || ServerInfo.servertype == 1:
		if Input.is_action_just_pressed("shop") && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
# warning-ignore:return_value_discarded
			ServerInfo.instance_node(ServerInfo.shop_module, self)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

remotesync func state_reset():
	var invi = preload("res://Scenes/effects/invincibilty.tscn").instance()
	is_ads = false
	isDead = false
	canMove = true
	is_sprinting = false
	stored_fall_damge = 0
	animation.play_backwards("ads")
	if is_network_master(): model_pos.visible = true
	model.visible = true
	torso_hb.get_child(0).disabled = false
	head_hb.get_child(0).disabled = false
	health = 100
	hp_bar.value = health
	speed = 500
	current_gun = secondary_slot
	add_new_gun("M1911")
	primary_slot = ""
	money = 1000
	add_child(invi, true)
	_update_ammo()
