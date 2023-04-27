extends Node2D

@onready var cellmap: CellMap
@onready var astar: AStar2D
@onready var n: RayCast2D = $N
@onready var s: RayCast2D = $S
@onready var e: RayCast2D = $E
@onready var w: RayCast2D = $W
@onready var mrpas: MRPAS = cellmap.build_mrpas_from_map()
var seen_tiles: Array[Vector2] = [] # TODO

# XXX: should there be a "player_state" function or something that returns stuff
# like where the player is in CellMap turns and stuff?  maybe have a signal like
# turn_taken(new_player_state)?

signal turn_taken(player_state: Dictionary)

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
	pass
#	astar.set_point_disabled(cellmap.get_cell_id(position))

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
#			astar.set_point_disabled(cellmap.get_cell_id(position), false)
#			astar.set_point_disabled(cellmap.get_cell_id(position+dv), true)
#			position = position+dv
			ready_to_move = false
			emit_signal("turn_taken", { 'new_position': position+dv })
			await create_tween().tween_property(self, 'position', position+dv, 0.1).finished
			ready_to_move = true

func update_fov(mobs: Array[Node], new_position: Vector2) -> void:
	""" Calculates the player's current fov and hides/shows mobs and cellmap cells based on it.  This, obviously, causes side effects! """
	var player_cell_pos: Vector2 = cellmap.world_pos_to_cell(new_position)
	mrpas.clear_field_of_view()
	mrpas.compute_field_of_view(player_cell_pos, 8)
	for c in cellmap.get_children(): # XXX: should the fov code for the player go in player.gd?
		if mrpas.is_in_view(cellmap.world_pos_to_cell(c.position)):
			c.show()
		else:
			c.hide()
	for m in mobs:
		var mob_cell_pos: Vector2 = cellmap.world_pos_to_cell(m.position)
		if mrpas.is_in_view(mob_cell_pos):
			m.show()
		else:
			m.hide()

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
func _process(delta) -> void:
	handle_movement()
