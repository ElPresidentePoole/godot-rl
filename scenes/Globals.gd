extends Node

# XXX: maybe this *does* belong in Player.gd?  No one else needs it.

const ALPHABET: String = 'abcdefghijklmnopqrstuvwxyz'

@onready var sounds: Dictionary = load_sounds()
@onready var beastiary: Dictionary = load_mobs()
@onready var armory: Dictionary = load_pickups()

enum MovementDirection {
	NORTH,
	SOUTH,
	EAST,
	WEST,
	NONE
	}

func load_mobs() -> Dictionary:
	var file: FileAccess = FileAccess.open("res://data/mobs.json", FileAccess.READ)
	return JSON.parse_string(file.get_as_text())
	
func load_pickups() -> Dictionary:
	var file: FileAccess = FileAccess.open("res://data/pickups.json", FileAccess.READ)
	return JSON.parse_string(file.get_as_text())

func load_sounds() -> Dictionary:
	var file: FileAccess = FileAccess.open("res://data/sounds.json", FileAccess.READ)
	var sounds_json: Dictionary = JSON.parse_string(file.get_as_text())
	var sounds_dict: Dictionary = {}
	for key in sounds_json:
		sounds_dict[key] = AudioStreamWAV.new()
		var sound_file_path: String = "res://sfx/{sfx_file}".format({'sfx_file': sounds_json[key]})
		sounds_dict[key].data = FileAccess.get_file_as_bytes(sound_file_path)
	return sounds_dict


func _ready():
	pass # TODO: json validation
	#if [beastiary, sounds].any(func(e): e == null):
