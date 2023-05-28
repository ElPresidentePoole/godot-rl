extends Node2D

const S_Item = preload('res://scenes/Item.tscn')
const S_Treasure = preload('res://scenes/Treasure.tscn')

@onready var symbol: Label = $Label
var pickup_key: String
var treasure: Node
var item: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	symbol.text = Globals.armory[pickup_key]['symbol']
	symbol.modulate = Color(Globals.armory[pickup_key]['color'])
	if Globals.armory[pickup_key].has('treasure'):
		treasure = S_Treasure.instantiate()
		treasure.value = Globals.armory[pickup_key]['treasure']['value']
		add_child(treasure)
	elif Globals.armory[pickup_key].has('item'):
		item = S_Item.instantiate()
		item.item_key = pickup_key
		add_child(item)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
