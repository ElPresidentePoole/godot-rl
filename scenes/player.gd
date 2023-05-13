extends Node2D

@onready var n: RayCast2D = $N
@onready var s: RayCast2D = $S
@onready var e: RayCast2D = $E
@onready var w: RayCast2D = $W
var mortality: Mortality = Mortality.new(self, 10)
@onready var hud: CanvasLayer = $HUDLayer

# XXX: should there be a "player_state" function or something that returns stuff
# like where the player is in CellMap turns and stuff?  maybe have a signal like
# turn_taken(new_player_state)?

signal request_to_move(dv: Vector2)

var ready_to_move: bool = true
var moving: Globals.MovementDirection = Globals.MovementDirection.NONE

func build_hplabel_text() -> String:
	return "HP: {hp}/{max_hp}".format({'hp': mortality.hp, 'max_hp': mortality.max_hp})

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HUDLayer/HP.text = build_hplabel_text()
	mortality.connect('hurt', func():
		var hpl = $HUDLayer/HP
		hpl.text = build_hplabel_text())

func handle_movement() -> void:
	if not ready_to_move:
		return
		
	var dv: Vector2 = Vector2()
	if moving == Globals.MovementDirection.NORTH:
		dv += Vector2(0, -1)
	elif moving == Globals.MovementDirection.SOUTH:
		dv += Vector2(0, 1)
	elif moving == Globals.MovementDirection.EAST:
		dv += Vector2(1, 0)
	elif moving == Globals.MovementDirection.WEST:
		dv += Vector2(-1, 0)
	elif moving == Globals.MovementDirection.NONE:
		dv = Vector2.ZERO

	if dv != Vector2.ZERO:
		emit_signal('request_to_move', dv)

func move(dv: Vector2) -> void:
	ready_to_move = false
	await create_tween().tween_property(self, 'position', position+dv, 0.1).finished
	ready_to_move = true

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_north"):
		moving = Globals.MovementDirection.NORTH
	elif event.is_action_pressed("move_south"):
		moving = Globals.MovementDirection.SOUTH
	elif event.is_action_pressed("move_east"):
		moving = Globals.MovementDirection.EAST
	elif event.is_action_pressed("move_west"):
		moving = Globals.MovementDirection.WEST

	if event.is_action_released("move_north") and moving == Globals.MovementDirection.NORTH \
		or event.is_action_released("move_south") and moving == Globals.MovementDirection.SOUTH \
		or event.is_action_released("move_east") and moving == Globals.MovementDirection.EAST \
		or event.is_action_released("move_west") and moving == Globals.MovementDirection.WEST:
		moving = Globals.MovementDirection.NONE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	handle_movement()
