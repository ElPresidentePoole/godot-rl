extends Node2D

@onready var cellmap: CellMap = $"CellMap"
@onready var astar: AStar2D = cellmap.astar
@onready var player: Actor = $"CellMap/Player"
@onready var player_hud: HUDLayer = $"CellMap/Player/HUDLayer"
var turn: int = 0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_north"):
		player_perform_action(MoveAction.new(player, Vector2i(0, -1)))
	elif Input.is_action_just_pressed("move_south"):
		player_perform_action(MoveAction.new(player, Vector2i(0, 1)))
	elif Input.is_action_just_pressed("move_west"):
		player_perform_action(MoveAction.new(player, Vector2i(-1, 0)))
	elif Input.is_action_just_pressed("move_east"):
		player_perform_action(MoveAction.new(player, Vector2i(1, 0)))

func player_perform_action(action):
	action.perform(self)
	
	for mob in $CellMap/Mobs.get_children():
		if mob.ai != null:
			var ai_action: Action = mob.ai.get_next_action(self)
			ai_action.perform(self)
	
	turn += 1
	player_hud.turn_label.text = "Turn: {t}".format({'t': turn})
