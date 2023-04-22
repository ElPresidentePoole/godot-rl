extends Node2D

class_name Cell

var cell_type: CellType = CellType.FLOOR
var blocks_movement: bool
#@export var blocks_vision: bool = false TODO
@onready var symbol: Label = $Symbol
@onready var bg: ColorRect = $Bg

enum CellType {
	FLOOR,
	WALL
	}

const CellProps: Dictionary = {
	CellType.FLOOR: {'blocks_movement': false, 'symbol': '.', 'bg': Color.BLACK},
	CellType.WALL: {'blocks_movement': true, 'symbol': '#', 'bg': Color.BLACK},
	}

func _update_cell_props() -> void:
	blocks_movement = CellProps[cell_type]['blocks_movement']
	symbol.text = CellProps[cell_type]['symbol']
	bg.modulate = CellProps[cell_type]['bg']

func set_cell_type(t: CellType) -> void:
	cell_type = t
	if is_inside_tree():
		_update_cell_props()

# Called when the node enters the scene tree for the first time.
func _ready():
	_update_cell_props()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
