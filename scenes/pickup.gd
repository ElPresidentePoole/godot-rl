extends Node2D

const S_Item = preload('res://scenes/item.tscn')

@onready var symbol: Label = $Label
var item_key: String
var item: Node

# Called when the node enters the scene tree for the first time.
func _ready():
	symbol.text = Globals.armory[item_key]['symbol']
	symbol.modulate = Color(Globals.armory[item_key]['color'])
	item = S_Item.instantiate()
	item.item_key = item_key
	add_child(item)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
