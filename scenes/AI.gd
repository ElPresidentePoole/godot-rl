extends Node

@onready var parent: Mob = get_parent()

func get_next_action(cellmap: CellMap) -> Action:
	var player_pos: Vector2i = cellmap.world_to_coords(cellmap.player.position)
	var parent_pos: Vector2i = cellmap.world_to_coords(parent.position)

	parent.mrpas.clear_field_of_view()
	parent.mrpas.compute_field_of_view(parent_pos, parent.vision_range)
	
	if parent.mrpas.is_in_view(player_pos):
#		last_seen = new_player_state['new_position']
		var closest: int = cellmap.astar.get_closest_point(player_pos)
		var cids: Dictionary = cellmap.get_astar_point_coords()
		var path: PackedVector2Array = cellmap.astar.get_point_path(cids[parent_pos], closest)
		if len(path) > parent.weapon.attack_range:
			# var dv: Vector2i = path[1]-cellmap.get_cell_pos(self) # iNvAliD oPeRaNdS vEcToR2 AnD vEcToR2I my ass
			var dv_x: int = path[1].x-cellmap.world_to_coords(parent.position).x
			var dv_y: int = path[1].y-cellmap.world_to_coords(parent.position).y
			var dv: Vector2i = Vector2i(dv_x, dv_y)
			print_debug(dv)
			return MoveAction.new(parent, dv, true)
	
	return Action.new(parent) # Do nothing lol
#		elif last_seen in path.slice(1, weapon.attack_range):
#			emit_signal("perform_game_action", GameAction.Actions.ATTACK, {'actor': self, 'victim': player, 'rof': weapon.attack_rof})
#	elif last_seen:
#		var closest: int = astar.get_closest_point(last_seen)
#		var path: PackedVector2Array = astar.get_point_path(cellmap.get_cell_id(position), closest)
#		if len(path) > 1 and path[1] != last_seen:
#			var dv: Vector2 = cellmap.world_pos_to_cell(path[1]-position)
#			emit_signal("perform_game_action", GameAction.Actions.MOVE, {'actor': self, 'dv': dv})
