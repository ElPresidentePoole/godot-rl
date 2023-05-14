extends Node

# XXX: maybe this *does* belong in Player.gd?  No one else needs it.

var beastiary: Dictionary = {}

enum MovementDirection {
	NORTH,
	SOUTH,
	EAST,
	WEST,
	NONE
	}

func load_mobs():
	var file: FileAccess = FileAccess.open("res://mobs.json", FileAccess.READ)
	beastiary = JSON.parse_string(file.get_as_text())
	print(beastiary)

func _ready():
	load_mobs()
