extends Area2D

var goes_down: bool
@onready var label: Label = $Label

# Called when the node enters the scene tree for the first time.
func _ready():
	if goes_down:
		label.text = '>'
	else:
		label.text = '<'
