extends Node2D

var mob_name: String
var vision_range: int
var last_seen: Vector2
var mob_key: String
@onready var mortality: Mortality = $Mortality
@onready var weapon: Weapon = $Weapon
@onready var label: Label = $Label
signal request_to_attack(perp)

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
	weapon.attack_verb = mob_data['weapon']['verb']
	mortality.max_hp = mob_data['mortality']['max_hp']

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass

func _physics_process(delta) -> void:
	pass
	
#func move(astar: AStar2D, cellmap: Node2D, dest: Vector2) -> void:
	# probably should make a dungeon.get_point_path and have the dungeon do more of the work than pass all this stuff in every time
#	var closest: int = astar.get_closest_point(dest)
#	var path: PackedVector2Array = astar.get_point_path(cellmap.get_cell_id(position), closest)
	# E 0:00:05:0121   mob.gd:21 @ move(): Can't get point path. Point with id: 3600 doesn't exist.
#  <C++ Error>    Condition "!from_exists" is true. Returning: Vector<Vector2>()
#  <C++ Source>   core/math/a_star.cpp:694 @ get_point_path()
#  <Stack Trace>  mob.gd:21 @ move()
#                 mob.gd:30 @ do_turn_behavior()
#                 dungeon.gd:90 @ process_turn()
#                 dungeon.gd:102 @ _on_player_request_to_move()
#                 player.gd:38 @ handle_movement()
#                 player.gd:63 @ _process()

#	if len(path) > 1 and path[1] != dest:
#		astar.set_point_disabled(cellmap.get_cell_id(position), false)
#		astar.set_point_disabled(cellmap.get_cell_id(path[1]), true)
#		await create_tween().tween_property(self, 'position', path[1], 0.1).finished

func do_turn_behavior(astar: AStar2D, mrpas: MRPAS, cellmap: Node2D, new_player_state: Dictionary) -> void:
	if mrpas.is_in_view(cellmap.world_pos_to_cell(new_player_state['new_position'])):
		last_seen = new_player_state['new_position']
		var closest: int = astar.get_closest_point(last_seen)
		var path: PackedVector2Array = astar.get_point_path(cellmap.get_cell_id(position), closest)
#		move(astar, cellmap, last_seen)
		if len(path) > weapon.attack_range and path[1] != last_seen:
			astar.set_point_disabled(cellmap.get_cell_id(position), false)
			astar.set_point_disabled(cellmap.get_cell_id(path[1]), true)
			await create_tween().tween_property(self, 'position', path[1], 0.1).finished
		elif last_seen in path.slice(1, weapon.attack_range):
			emit_signal('request_to_attack', self)
	elif last_seen:
		var closest: int = astar.get_closest_point(last_seen)
		var path: PackedVector2Array = astar.get_point_path(cellmap.get_cell_id(position), closest)
		if len(path) > 1 and path[1] != last_seen:
			astar.set_point_disabled(cellmap.get_cell_id(position), false)
			astar.set_point_disabled(cellmap.get_cell_id(path[1]), true)
			await create_tween().tween_property(self, 'position', path[1], 0.1).finished
#	elif last_seen != null and last_seen != cellmap.world_pos_to_cell(position):
#		move(new_player_state['new_position'])
