extends Node2D

const S_Player: PackedScene = preload("res://scenes/player.tscn")
const S_Mob: PackedScene = preload("res://scenes/mob.tscn")
const S_Cell: PackedScene = preload("res://scenes/cell.tscn")

@onready var _cellmap: CellMap = $CellMap

func get_cellmap() -> CellMap:
	return _cellmap

func get_astar() -> AStar2D:
	return get_cellmap().astar

func spawn_player(x: int, y: int) -> void:
	var p = S_Player.instantiate()
	p.position = Vector2(x, y) * _cellmap.CELL_SIZE
	add_child(p)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var player_pos: Vector2 = _cellmap.root.get_leaves()[0].get_room_center()
	spawn_player(player_pos.x, player_pos.y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass
