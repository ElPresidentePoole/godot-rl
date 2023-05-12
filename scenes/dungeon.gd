extends Node2D

const S_Player: PackedScene = preload("res://scenes/player.tscn")
const S_Mob: PackedScene = preload("res://scenes/mob.tscn")
const S_Cell: PackedScene = preload("res://scenes/cell.tscn")

@onready var mobs: Node = $Mobs
@onready var cellmap: CellMap = $CellMap
@onready var player_mrpas: MRPAS = cellmap.build_mrpas_from_map()
@onready var astar: AStar2D = $CellMap.astar
@onready var player: Node2D = $Player
var player_seen_tiles: Array[Vector2] = [] # TODO

signal turn_taken(player_state: Dictionary)

func get_cellmap() -> CellMap:
	return cellmap

func get_astar() -> AStar2D:
	return get_cellmap().astar

func spawn_player(x: int, y: int) -> void:
	# TODO: come back to this after refactoring
	var p = player
	p.position = Vector2(x, y) * cellmap.CELL_SIZE
#	p.connect('turn_taken', func (new_player_state):
#		for m in mobs.get_children():
#			m._on_player_turn_taken(new_player_state)
#		update_player_fov(new_player_state['new_position']))
#	add_child(p)
	update_player_fov(cellmap.world_pos_to_cell(p.position)) # why it still broke?

func spawn_mob(x: int, y: int) -> void:
	var m = S_Mob.instantiate()
	m.position = Vector2(x, y) * cellmap.CELL_SIZE
	m.cellmap = get_cellmap()
	m.astar = get_astar()
	mobs.add_child(m)

func update_player_fov(new_position: Vector2) -> void:
	""" Calculates the player's current fov and hides/shows mobs and cellmap cells based on it.  This, obviously, causes side effects! """
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
			c.symbol.modulate = Color.LIGHT_STEEL_BLUE
		else:
			c.hide()
	for m in mobs.get_children():
		var mob_cell_pos: Vector2 = cellmap.world_pos_to_cell(m.position)
		if player_mrpas.is_in_view(mob_cell_pos):
			m.show()
		else:
			m.hide()

func _on_player_attempt_to_move(dv) -> void:
	dv *= cellmap.CELL_SIZE
	if not astar.is_point_disabled(cellmap.get_cell_id(player.position+dv)):
##			astar.set_point_disabled(cellmap.get_cell_id(position), false)
##			astar.set_point_disabled(cellmap.get_cell_id(position+dv), true)
###			position = position+dv
		player.ready_to_move = false
		emit_signal("turn_taken", { 'new_position': player.position+dv })
		await create_tween().tween_property(player, 'position', player.position+dv, 0.1).finished
		player.ready_to_move = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player_pos: Vector2 = cellmap.root.get_leaves()[0].get_room_center()
	spawn_player(player_pos.x, player_pos.y)
#	var mob_pos: Vector2 = cellmap.root.get_leaves()[1].get_room_center()
#	spawn_mob(mob_pos.x, mob_pos.y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass


func _on_turn_taken(player_state):
	update_player_fov(player.position) # why it still broke?
