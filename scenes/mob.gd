class_name Mob extends "res://scenes/Actor.gd"

var last_seen: Vector2
var mob_key: String
var ready_to_act: bool = true
@onready var weapon: Weapon = $Weapon
@onready var ai: Node = $AI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(mob_key != null && mob_key in Globals.beastiary)
	var mob_data: Dictionary = Globals.beastiary[mob_key]
	vision_range = mob_data['vision_range']
	mob_name = mob_data['mob_name']
	label.text = mob_data['symbol']
	label.modulate = Color(mob_data['color'])
	weapon.attack_range = mob_data['weapon']['range']
	weapon.attack_damage = mob_data['weapon']['damage']
	weapon.attack_rof = mob_data['weapon']['rof']
	weapon.attack_verb = mob_data['weapon']['verb']
	attack_sound.stream = Globals.sounds[mob_data['weapon']['sound']]
	mortality.max_hp = mob_data['mortality']['max_hp']
	mortality.hp = mortality.max_hp

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass

func _physics_process(delta) -> void:
	pass
	
func move(astar: AStar2D, cellmap: Node2D, dest: Vector2) -> void:
	astar.set_point_disabled(cellmap.get_cell_id(position), false)
	astar.set_point_disabled(cellmap.get_cell_id(dest), true)
	await create_tween().tween_property(self, 'position', dest, 0.1).finished
