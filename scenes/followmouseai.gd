extends Node2D

@onready var astar: AStar2D = get_parent().get_astar()
@onready var cellmap: CellMap = get_parent().get_cellmap()
var destination: Vector2

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
	
func move() -> void:
	var closest: int = astar.get_closest_point(get_global_mouse_position())
	var path: PackedVector2Array = astar.get_point_path(cellmap.get_cell_id(position), closest)
	if len(path) > 1:
		astar.set_point_disabled(cellmap.get_cell_id(position), false)
		position = path[1]
		astar.set_point_disabled(cellmap.get_cell_id(position))

func _on_move_timer_timeout():
	move()
