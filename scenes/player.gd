extends Node2D

@onready var cellmap: CellMap = get_parent().get_cellmap()
@onready var astar: AStar2D = get_parent().get_astar()
@onready var n: RayCast2D = $N
@onready var s: RayCast2D = $S
@onready var e: RayCast2D = $E
@onready var w: RayCast2D = $W

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	astar.set_point_disabled(cellmap.get_cell_id(position))

func _unhandled_input(event: InputEvent) -> void:
	var dv: Vector2 = Vector2()
	if event.is_action_pressed("move_north"):
		dv += Vector2(0, -1)
	elif event.is_action_pressed("move_south"):
		dv += Vector2(0, 1)
	elif event.is_action_pressed("move_east"):
		dv += Vector2(1, 0)
	elif event.is_action_pressed("move_west"):
		dv += Vector2(-1, 0)

	if dv != Vector2.ZERO:
		dv *= cellmap.CELL_SIZE
		if not astar.is_point_disabled(cellmap.get_cell_id(position+dv)):
			astar.set_point_disabled(cellmap.get_cell_id(position), false)
			position = position+dv
			astar.set_point_disabled(cellmap.get_cell_id(position))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass
