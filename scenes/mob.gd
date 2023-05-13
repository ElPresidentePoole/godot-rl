extends Node2D

var last_seen: Vector2
var mortality: Mortality = Mortality.new(self, 3)
const VIEW_DISTANCE: int = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass

func _physics_process(delta) -> void:
	pass
	
func move(astar: AStar2D, cellmap: Node2D, dest: Vector2) -> void:
	# probably should make a dungeon.get_point_path and have the dungeon do more of the work than pass all this stuff in every time
	var closest: int = astar.get_closest_point(dest)
	var path: PackedVector2Array = astar.get_point_path(cellmap.get_cell_id(position), closest)
	if len(path) > 1 and path[1] != dest:
		astar.set_point_disabled(cellmap.get_cell_id(position), false)
		astar.set_point_disabled(cellmap.get_cell_id(path[1]), true)
		await create_tween().tween_property(self, 'position', path[1], 0.1).finished

func do_turn_behavior(astar: AStar2D, mrpas: MRPAS, cellmap: Node2D, new_player_state: Dictionary) -> void:
	if mrpas.is_in_view(cellmap.world_pos_to_cell(new_player_state['new_position'])):
		last_seen = new_player_state['new_position']
		move(astar, cellmap, new_player_state['new_position'])
#	elif last_seen != null and last_seen != cellmap.world_pos_to_cell(position):
#		move(new_player_state['new_position'])
