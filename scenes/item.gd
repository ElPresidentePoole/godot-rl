extends Node

const S_Weapon = preload("res://scenes/weapon.tscn")
const S_Treasure = preload("res://scenes/treasure.tscn")

var item_key: String
@onready var item_name: String = Globals.armory[item_key]['item_name']

# Called when the node enters the scene tree for the first time.
func _ready():
	var item_data: Dictionary = Globals.armory[item_key]
	if item_data.has('weapon'):
		var w: Node = S_Weapon.instantiate()
		w.attack_range = item_data['weapon']['range']
		w.attack_damage = item_data['weapon']['damage']
		w.attack_rof = item_data['weapon']['rof']
		w.attack_verb = item_data['weapon']['verb']
		add_child(w)
	elif item_data.has('treasure'):
		var t: Node = S_Treasure.instantiate()
		t.value = item_data['treasure']['value']
		add_child(t)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
