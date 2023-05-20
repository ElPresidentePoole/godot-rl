extends Node2D

@onready var n: RayCast2D = $N
@onready var s: RayCast2D = $S
@onready var e: RayCast2D = $E
@onready var w: RayCast2D = $W
@onready var pickup_check_area: Area2D = $PickupCheckArea
@onready var stairs_check_area: Area2D = $StairsCheckArea
@onready var hud: CanvasLayer = $HUDLayer
@onready var mortality: Mortality = $Mortality
@onready var weapon: Weapon = $Weapon
@onready var inventory: Node = $Inventory
@onready var attack_sound: AudioStreamPlayer = $AttackSound
@onready var treasure_sound: AudioStreamPlayer = $TreasureSound
var mob_name: String = "Adventurer"

signal perform_game_action(action: GameAction.Actions, data: Dictionary)
signal stairs_down()
signal obtained_new_item(item_name: String, item_occupying_slot: int)

var ready_to_act: bool = true
var gold: int = 0
var moving: Globals.MovementDirection = Globals.MovementDirection.NONE

func build_hplabel_text() -> String:
	return "HP: {hp}/{max_hp}".format({'hp': mortality.hp, 'max_hp': mortality.max_hp})

func build_goldlabel_text() -> String:
	return "Gold: {au}".format({'au': gold})

func build_inventoryspacelabel_text() -> String:
	return "Inventory: {used}/26".format({'used': inventory.get_child_count()})

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mortality.max_hp = 10
	mortality.hp = mortality.max_hp
	weapon.attack_range = 10
	weapon.attack_damage = 5
	weapon.attack_verb = 'shoots'
	hud.hp_label.text = build_hplabel_text()
	hud.gold_label.text = build_goldlabel_text()
	hud.inventory_label.text = build_inventoryspacelabel_text()
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
	var picked_up: bool = false
	for a in areas_colliding:
		if a.has_node('Treasure'):
			a.queue_free()
			gold += a.get_node('Treasure').value
			hud.gold_label.text = build_goldlabel_text()
			hud.log_container.add_entry("You pick up {amount} gold.".format({'amount': a.get_node('Treasure').value}))
			picked_up = true
		elif inventory.get_child_count() < 26:
			hud.log_container.add_entry("You pick up the {item}.".format({'item': a.item.item_name}))
			a.item.reparent(self.inventory)
			emit_signal('obtained_new_item', a.item.item_name, inventory.get_child_count())
			a.queue_free()
			picked_up = true
	if picked_up:
		treasure_sound.play()
		hud.inventory_label.text = build_inventoryspacelabel_text()

func move(_astar: AStar2D, _cellmap: Node2D, dest: Vector2) -> void:
	await create_tween().tween_property(self, 'position', dest, 0.1).finished

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_north"):
		moving = Globals.MovementDirection.NORTH
	elif event.is_action_pressed("move_south"):
		moving = Globals.MovementDirection.SOUTH
	elif event.is_action_pressed("move_east"):
		moving = Globals.MovementDirection.EAST
	elif event.is_action_pressed("move_west"):
		moving = Globals.MovementDirection.WEST
	elif event.is_action_pressed("fire_at_nearest_mob") and ready_to_act:
		emit_signal("perform_game_action", GameAction.Actions.AIM, {'actor': self})
	elif event.is_action_pressed("go_down_stairs") and ready_to_act:
		var available_stairs: Array[Area2D] = stairs_check_area.get_overlapping_areas()
		if available_stairs.any(func(stair): return stair.goes_down): emit_signal('stairs_down')
	elif event.is_action_pressed("grab_pickup") and ready_to_act:
		var available_pickups: Array[Area2D] = pickup_check_area.get_overlapping_areas()
		if available_pickups: pickup_items_below_me(available_pickups)
	elif event.is_action_pressed("view_inventory") and ready_to_act:
		hud.inventory_panel.visible = not hud.inventory_panel.visible

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
