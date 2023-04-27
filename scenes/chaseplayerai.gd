extends Node2D

@onready var astar: AStar2D
@onready var cellmap: CellMap
@onready var mrpas: MRPAS = cellmap.build_mrpas_from_map()
var destination: Vector2
const VIEW_DISTANCE: int = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var cid: int = cellmap.get_cell_id(position)
	astar.set_point_disabled(cid)
	# astar.set_point_disabled(cellmap.get_cell_id(position), true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass

func _physics_process(delta) -> void:
	pass
	
func move(dest: Vector2) -> void:
	var closest: int = astar.get_closest_point(dest)
	var path: PackedVector2Array = astar.get_point_path(cellmap.get_cell_id(position), closest)
	if len(path) > 1 and path[1] != dest:
		astar.set_point_disabled(cellmap.get_cell_id(position), false)
		astar.set_point_disabled(cellmap.get_cell_id(path[1]), true)
		#position = path[1]
		await create_tween().tween_property(self, 'position', path[1], 0.1).finished

func _on_player_turn_taken(new_player_state: Dictionary) -> void:
	mrpas.clear_field_of_view()
	mrpas.compute_field_of_view(cellmap.world_pos_to_cell(position), VIEW_DISTANCE)
	if mrpas.is_in_view(cellmap.world_pos_to_cell(new_player_state['new_position'])):
		move(new_player_state['new_position'])
