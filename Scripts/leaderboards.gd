extends Control

onready var container = $Panel/container
onready var score = $Panel/container2

func _process(_delta):
	if get_tree().is_network_server():
		rpc_unreliable("update_board")


sync func update_board():
	if Players.get_child_count() > 0:
		for i in container.get_children():
			i.queue_free()
		for p in score.get_children():
			p.queue_free()
		for e in Players.get_children():
			var new_label = Label.new()
			var new_score_l = Label.new()
			new_label.text = e.username
			new_label.align = Label.ALIGN_CENTER
			new_score_l.align = Label.ALIGN_CENTER
			new_score_l.text = str(e.dm_kills) + "    :    " + str(0)
			container.add_child(new_label, true)
			score.add_child(new_score_l,true)
