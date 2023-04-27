extends Node2D

const S_Player: PackedScene = preload("res://scenes/player.tscn")
const S_Mob: PackedScene = preload("res://scenes/mob.tscn")
const S_Cell: PackedScene = preload("res://scenes/cell.tscn")

@onready var mobs: Node = $Mobs
@onready var _cellmap: CellMap = $CellMap

func get_cellmap() -> CellMap:
	return _cellmap

func get_astar() -> AStar2D:
	return get_cellmap().astar

func spawn_player(x: int, y: int) -> void:
	var p = S_Player.instantiate()
	p.position = Vector2(x, y) * _cellmap.CELL_SIZE
	p.cellmap = get_cellmap()
	p.astar = get_astar()
	p.connect('turn_taken', func (new_player_state):
		for m in mobs.get_children():
			m._on_player_turn_taken(new_player_state)
		p.update_fov(mobs.get_children(), new_player_state['new_position']))
	add_child(p)
	p.update_fov(mobs.get_children(), _cellmap.world_pos_to_cell(p.position)) # why it still broke?

func spawn_mob(x: int, y: int) -> void:
	var m = S_Mob.instantiate()
	m.position = Vector2(x, y) * _cellmap.CELL_SIZE
	m.cellmap = get_cellmap()
	m.astar = get_astar()
	mobs.add_child(m)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player_pos: Vector2 = _cellmap.root.get_leaves()[0].get_room_center()
	spawn_player(player_pos.x, player_pos.y)
	var mob_pos: Vector2 = _cellmap.root.get_leaves()[1].get_room_center()
	spawn_mob(mob_pos.x, mob_pos.y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass
