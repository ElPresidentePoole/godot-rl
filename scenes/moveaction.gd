class_name MoveAction extends Action

var dv: Vector2i

func _init(actor: Actor, dv: Vector2i) -> void:
	super(actor)
	self.dv = dv

# TODO: only await/tween when in view /will be in view of player
func perform(parent: Node) -> void:
	var pos_final: Vector2i = parent.node_to_cell_pos_map[actor] + dv
	if parent.astar.is_point_disabled(parent.astar.get_closest_point(pos_final, true)):
		# player.hud.log_container.add_entry("I can't move there!")
		pass # TODO: "can't do that" message
	else: # TODO elif in_player_fov:
		var world_pos_final: Vector2 = parent.cell_pos_to_world(pos_final)
		await actor.play_movement_tween(world_pos_final)
		parent.node_to_cell_pos_map[actor] = pos_final
