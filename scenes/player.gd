extends Node2D

@onready var n: RayCast2D = $N
@onready var s: RayCast2D = $S
@onready var e: RayCast2D = $E
@onready var w: RayCast2D = $W
@onready var here_area: Area2D = $PickupArea
@onready var hud: CanvasLayer = $HUDLayer
@onready var mortality: Mortality = $Mortality
@onready var weapon: Weapon = $Weapon
var mob_name: String = "Adventurer"

# XXX: should there be a "player_state" function or something that returns stuff
# like where the player is in CellMap turns and stuff?  maybe have a signal like
# turn_taken(new_player_state)?

signal request_to_move(dv: Vector2)
signal fire_at_nearest_mob()

var ready_to_move: bool = true
var gold: int = 0
var moving: Globals.MovementDirection = Globals.MovementDirection.NONE

func build_hplabel_text() -> String:
	return "HP: {hp}/{max_hp}".format({'hp': mortality.hp, 'max_hp': mortality.max_hp})

func build_goldlabel_text() -> String:
	return "Gold: {au}".format({'au': gold})

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hud.hp_label.text = build_hplabel_text()
	hud.gold_label.text = build_goldlabel_text()
	mortality.connect('hurt', func():
		var hpl = hud.hp_label
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

func pickup_items_below_me() -> void:
	for item in here_area.get_overlapping_areas():
		# TODO for now there's just gold and we don't need to check if the collider with this area 
		item.queue_free()
		gold += item.value
		hud.gold_label.text = build_goldlabel_text()
		hud.log_container.add_entry("You pick up {amount} gold.".format({'amount': item.value}))

func move(dv: Vector2) -> void:
	ready_to_move = false
	await create_tween().tween_property(self, 'position', position+dv, 0.1).finished
	ready_to_move = true
	pickup_items_below_me()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_north"):
		moving = Globals.MovementDirection.NORTH
	elif event.is_action_pressed("move_south"):
		moving = Globals.MovementDirection.SOUTH
	elif event.is_action_pressed("move_east"):
		moving = Globals.MovementDirection.EAST
	elif event.is_action_pressed("move_west"):
		moving = Globals.MovementDirection.WEST
	elif event.is_action_pressed("fire_at_nearest_mob"):
		# TODO: wait a bit, also we're spamming shots
		# are we firing too fast or what?  we just insta-vaporize mobs
		emit_signal('fire_at_nearest_mob')

	if event.is_action_released("move_north") and moving == Globals.MovementDirection.NORTH \
		or event.is_action_released("move_south") and moving == Globals.MovementDirection.SOUTH \
		or event.is_action_released("move_east") and moving == Globals.MovementDirection.EAST \
		or event.is_action_released("move_west") and moving == Globals.MovementDirection.WEST:
		moving = Globals.MovementDirection.NONE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	handle_movement()
