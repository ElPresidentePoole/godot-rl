extends Node

class_name Weapon

# TODO: make "Weapon" an Item with an Attack component
# so like, move this a layer down.
# composition ftw!

var attack_range: int
var attack_damage: int
var attack_verb: String
var attack_rof: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
