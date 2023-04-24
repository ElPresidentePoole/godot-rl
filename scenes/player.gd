extends Node2D

@onready var cellmap: CellMap = get_parent().get_cellmap()
@onready var astar: AStar2D = get_parent().get_astar()
@onready var n: RayCast2D = $N
@onready var s: RayCast2D = $S
@onready var e: RayCast2D = $E
@onready var w: RayCast2D = $W

var ready_to_move: bool = true

enum MovementDirection {
	NORTH,
	SOUTH,
	EAST,
	WEST,
	NONE
	}

var moving: MovementDirection = MovementDirection.NONE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	astar.set_point_disabled(cellmap.get_cell_id(position))

func handle_movement() -> void:
	if not ready_to_move:
		return
		
	var dv: Vector2 = Vector2()
	if moving == MovementDirection.NORTH:
		dv += Vector2(0, -1)
	elif moving == MovementDirection.SOUTH:
		dv += Vector2(0, 1)
	elif moving == MovementDirection.EAST:
		dv += Vector2(1, 0)
	elif moving == MovementDirection.WEST:
		dv += Vector2(-1, 0)
	elif moving == MovementDirection.NONE:
		dv = Vector2.ZERO

	if dv != Vector2.ZERO:
		dv *= cellmap.CELL_SIZE
		if not astar.is_point_disabled(cellmap.get_cell_id(position+dv)):
			astar.set_point_disabled(cellmap.get_cell_id(position), false)
			astar.set_point_disabled(cellmap.get_cell_id(position+dv), true)
#			position = position+dv
			ready_to_move = false
			await create_tween().tween_property(self, 'position', position+dv, 0.1).finished
			ready_to_move = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_north"):
		moving = MovementDirection.NORTH
	elif event.is_action_pressed("move_south"):
		moving = MovementDirection.SOUTH
	elif event.is_action_pressed("move_east"):
		moving = MovementDirection.EAST
	elif event.is_action_pressed("move_west"):
		moving = MovementDirection.WEST

	if event.is_action_released("move_north") and moving == MovementDirection.NORTH \
		or event.is_action_released("move_south") and moving == MovementDirection.SOUTH \
		or event.is_action_released("move_east") and moving == MovementDirection.EAST \
		or event.is_action_released("move_west") and moving == MovementDirection.WEST:
		moving = MovementDirection.NONE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta) -> void:
	handle_movement()
