extends Node2D

const S_Player: PackedScene = preload("res://scenes/player.tscn")
const S_Mob: PackedScene = preload("res://scenes/mob.tscn")
const S_Cell: PackedScene = preload("res://scenes/cell.tscn")

@onready var mobs: Node = $Mobs
@onready var cellmap: CellMap = $CellMap
@onready var astar: AStar2D = $CellMap.astar
@onready var player: Node2D = $Player
@onready var player_mrpas: MRPAS = cellmap.build_mrpas_from_map()
var player_seen_tiles: Array[Vector2] = [] # TODO

func get_cellmap() -> CellMap:
	return cellmap # TODO: remove, not needed

func get_astar() -> AStar2D:
	return get_cellmap().astar # TODO: remove, not needed

func place_player(x: int, y: int) -> void:
	""" Places a player somewhere and then updates fov """
	var p = player
	p.position = Vector2(x, y) * cellmap.CELL_SIZE
	update_player_fov(p.position)

func spawn_mob(x: int, y: int) -> void:
	var m = S_Mob.instantiate()
	m.position = Vector2(x, y) * cellmap.CELL_SIZE
	mobs.add_child(m)

func update_player_fov(new_position: Vector2) -> void:
	""" Calculates the player's current fov and hides/shows mobs and cellmap cells based on it.  This, obviously, causes side effects! 
	Future note: What side effects?  We aren't doing functional programming?  Also new_position should WORLD position, not cell map position.
	"""
	var player_cell_pos: Vector2 = cellmap.world_pos_to_cell(new_position)
	player_mrpas.clear_field_of_view()
	player_mrpas.compute_field_of_view(player_cell_pos, 8)
	for c in cellmap.get_children():
		var cell_pos: Vector2 = cellmap.world_pos_to_cell(c.position)
		if player_mrpas.is_in_view(cell_pos):
			if not cell_pos in player_seen_tiles:
				player_seen_tiles.append(cell_pos)
			c.show()
			c.symbol.modulate = Color.WHITE
		elif cell_pos in player_seen_tiles:
			c.show()
			c.symbol.modulate = Color.DARK_RED
		else:
			c.hide()
	for m in mobs.get_children():
		var mob_cell_pos: Vector2 = cellmap.world_pos_to_cell(m.position)
		if player_mrpas.is_in_view(mob_cell_pos):
			m.show()
		else:
			m.hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var spawn_room: Vector2 = cellmap.root.get_leaves()[0].get_room_center()
	place_player(spawn_room.x, spawn_room.y)
#	var mob_pos: Vector2 = cellmap.root.get_leaves()[1].get_room_center()
#	spawn_mob(mob_pos.x, mob_pos.y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass

func process_turn(player_state):
	update_player_fov(player.position) # why it still broke?

func _on_player_request_to_move(dv):
	dv *= cellmap.CELL_SIZE
	if not astar.is_point_disabled(cellmap.get_cell_id(player.position+dv)):
##			astar.set_point_disabled(cellmap.get_cell_id(position), false)
##			astar.set_point_disabled(cellmap.get_cell_id(position+dv), true)
###			position = position+dv
		process_turn({ 'new_position': player.position+dv })
		player.move(dv)
