extends Node

@onready var parent: Mob = get_parent()

func get_next_action(dungeon: Node2D) -> Action:
	var player_pos: Vector2i = dungeon.cellmap.get_cell_pos(dungeon.player)
	var parent_pos: Vector2i = dungeon.cellmap.get_cell_pos(parent)
	
	if parent.mrpas.is_in_view(player_pos):
#		last_seen = new_player_state['new_position']
		var closest: int = dungeon.astar.get_closest_point(player_pos)
		var path: PackedVector2Array = dungeon.astar.get_point_path(dungeon.cellmap.get_cell_id(parent_pos), closest)
		if len(path) > parent.weapon.attack_range:
			var dv: Vector2i = path[1]-dungeon.cellmap.get_cell_pos(self)
			print_debug(dv)
			return MoveAction.new(parent, dv)
	
	return Action.new(parent) # Do nothing lol
#		elif last_seen in path.slice(1, weapon.attack_range):
#			emit_signal("perform_game_action", GameAction.Actions.ATTACK, {'actor': self, 'victim': player, 'rof': weapon.attack_rof})
#	elif last_seen:
#		var closest: int = astar.get_closest_point(last_seen)
#		var path: PackedVector2Array = astar.get_point_path(cellmap.get_cell_id(position), closest)
#		if len(path) > 1 and path[1] != last_seen:
#			var dv: Vector2 = cellmap.world_pos_to_cell(path[1]-position)
#			emit_signal("perform_game_action", GameAction.Actions.MOVE, {'actor': self, 'dv': dv})
