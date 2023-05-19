extends Node2D

@onready var n: RayCast2D = $N
@onready var s: RayCast2D = $S
@onready var e: RayCast2D = $E
@onready var w: RayCast2D = $W
@onready var here_area: Area2D = $HereArea
@onready var hud: CanvasLayer = $HUDLayer
@onready var mortality: Mortality = $Mortality
@onready var weapon: Weapon = $Weapon
@onready var inventory: Node = $Inventory
@onready var attack_sound: AudioStreamPlayer = $AttackSound
@onready var treasure_sound: AudioStreamPlayer = $TreasureSound
var mob_name: String = "Adventurer"

signal perform_game_action(action: GameAction.Actions, data: Dictionary)
signal stairs_down()

var ready_to_act: bool = true
var gold: int = 0
var moving: Globals.MovementDirection = Globals.MovementDirection.NONE

func build_hplabel_text() -> String:
	return "HP: {hp}/{max_hp}".format({'hp': mortality.hp, 'max_hp': mortality.max_hp})

func build_goldlabel_text() -> String:
	return "Gold: {au}".format({'au': gold})

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mortality.max_hp = 10
	mortality.hp = mortality.max_hp
	weapon.attack_range = 10
	weapon.attack_damage = 5
	weapon.attack_verb = 'shoots'
	hud.hp_label.text = build_hplabel_text()
	hud.gold_label.text = build_goldlabel_text()
#	attack_sound.sound

func handle_movement() -> void:
	if not ready_to_act:
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
		emit_signal("perform_game_action", GameAction.Actions.MOVE, {'actor': self, 'dv': dv})

func pickup_items_below_me(areas_colliding: Array[Area2D]) -> void:
	for a in areas_colliding:
		#if a.is_in_group('stairs'): # TODO: make this require a keypress than being automatic
			#emit_signal('stairs_down')
		if a.has_node('Treasure'):
			a.queue_free()
			gold += a.get_node('Treasure').value
			hud.gold_label.text = build_goldlabel_text()
			hud.log_container.add_entry("You pick up {amount} gold.".format({'amount': a.get_node('Treasure').value}))
		else:
			hud.log_container.add_entry("You pick up the {item}.".format({'item': a.item.item_name}))
			a.item.reparent(self.inventory)
			a.queue_free()
	if not areas_colliding.is_empty():
		treasure_sound.play()

func move(_astar: AStar2D, _cellmap: Node2D, dest: Vector2) -> void:
	await create_tween().tween_property(self, 'position', dest, 0.1).finished

	var colliders: Array[Area2D] = here_area.get_overlapping_areas()
	if colliders.any(func (e):
		e.is_in_group('stairs')):
		emit_signal('stairs')
	else:
		pickup_items_below_me(colliders)

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
		emit_signal("perform_game_action", GameAction.Actions.AIM, {'actor': self})

	if event.is_action_released("move_north") and moving == Globals.MovementDirection.NORTH \
		or event.is_action_released("move_south") and moving == Globals.MovementDirection.SOUTH \
		or event.is_action_released("move_east") and moving == Globals.MovementDirection.EAST \
		or event.is_action_released("move_west") and moving == Globals.MovementDirection.WEST:
		moving = Globals.MovementDirection.NONE

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	handle_movement()


func _on_mortality_hurt():
	var hpl = hud.hp_label
	hpl.text = build_hplabel_text()
