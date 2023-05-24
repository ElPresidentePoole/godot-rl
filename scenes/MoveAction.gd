class_name MoveAction extends Action

var dv: Vector2i
var modify_astar: bool

func _init(actor: Actor, dv: Vector2i, modify_astar: bool = false) -> void:
	super(actor)
	self.dv = dv
	self.modify_astar = modify_astar

# TODO: only await/tween when in view /will be in view of player
func perform(parent: Node) -> void:
	var pos_final: Vector2i = parent.world_to_coords(actor.position) + dv
	var pid_at_pos_current: int = parent.get_astar_point_coords()[parent.world_to_coords(actor.position)]
	var pid_at_pos_final: int = parent.get_astar_point_coords()[pos_final]
	if parent.astar.is_point_disabled(pid_at_pos_final):
		# player.hud.log_container.add_entry("I can't move there!")
		# TODO: "can't do that" message
		emit_signal("action_completed", self)
	else: # TODO elif in_player_fov:
		var world_pos_final: Vector2 = parent.coords_to_world(pos_final)
		if modify_astar:
			parent.astar.set_point_disabled(pid_at_pos_current, false)
			parent.astar.set_point_disabled(pid_at_pos_final, true)
		await actor.play_movement_tween(world_pos_final)
		emit_signal("action_completed", self)

		# FIXME: does not update astar for mobs!
