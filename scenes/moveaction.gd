class_name MoveAction extends Action

var dv: Vector2i

func _init(actor: Node, dv: Vector2i) -> void:
	self.actor = actor
	self.dv = dv

func perform(parent: Node) -> void:
	pass
'''
	var pos_final: Vector2 = actor.position + parent.cellmap.cell_pos_to_world(dv)
	# TODO: check if points are connected
	if parent.astar.is_point_disabled(parent.astar.get_closest_point(pos_final, true)):
		# player.hud.log_container.add_entry("I can't move there!")
		pass
	else:
		actor.ready_to_act = false
		# does this await break anything else? getting close to the deadline here and it fixed the attack animation crash when changing levels while being shot at
		await actor.move(astar, cellmap, pos_final)
		actor.ready_to_act = true
		action_successful = true
'''
