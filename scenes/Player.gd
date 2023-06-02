extends "res://scenes/Actor.gd"

@onready var hud: CanvasLayer = $HUDLayer
@onready var weapon: Weapon = $Weapon
@onready var inventory: Node = $Inventory
@onready var treasure_sound: AudioStreamPlayer = $TreasureSound

signal new_action(action: Action)
#signal stairs_down()
#signal obtained_new_item(item_name: String, item_occupying_slot: int)

var gold: int = 0

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
	actor_name = "Player"
	mortality.connect("hurt", func():
		hud.hp_label.text = build_hplabel_text())

func handle_movement() -> void:
	pass

#func pickup_items_below_me(areas_colliding: Array[Area2D]) -> void:
#	var picked_up: bool = false
#	for a in areas_colliding:
#		if a.has_node('Treasure'):
#			a.queue_free()
#			gold += a.get_node('Treasure').value
#			hud.gold_label.text = build_goldlabel_text()
#			hud.log_container.add_entry("You pick up {amount} gold.".format({'amount': a.get_node('Treasure').value}))
#			picked_up = true
#		elif inventory.get_child_count() < 26:
#			hud.log_container.add_entry("You pick up the {item}.".format({'item': a.item.item_name}))
#			a.item.reparent(self.inventory)
#			emit_signal('obtained_new_item', a.item.item_name, inventory.get_child_count())
#			a.queue_free()
#			picked_up = true
#	if picked_up:
#		treasure_sound.play()
#		hud.inventory_label.text = build_inventoryspacelabel_text()

#func move(_astar: AStar2D, _cellmap: Node2D, dest: Vector2) -> void:
#	await create_tween().tween_property(self, 'position', dest, 0.1).finished

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass

func _on_mortality_hurt():
	var hpl = hud.hp_label
	hpl.text = build_hplabel_text()
