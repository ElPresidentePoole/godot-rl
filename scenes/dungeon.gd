extends Node2D

@onready var cellmap: CellMap = $"CellMap"
@onready var astar: AStar2D = cellmap.astar
@onready var player: Actor = $"CellMap/Player"

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("move_north"):
		player.emit_signal('perform_action', MoveAction.new(player, Vector2i(0, -1)))
	elif Input.is_action_just_pressed("move_south"):
		player.emit_signal('perform_action', MoveAction.new(player, Vector2i(0, 1)))
	elif Input.is_action_just_pressed("move_west"):
		player.emit_signal('perform_action', MoveAction.new(player, Vector2i(-1, 0)))
	elif Input.is_action_just_pressed("move_east"):
		player.emit_signal('perform_action', MoveAction.new(player, Vector2i(1, 0)))

func _on_player_perform_action(action):
	action.perform(self)
	
	for mob in $CellMap/Mobs.get_children():
		if mob.ai != null:
			var ai_action: Action = mob.ai.get_next_action(self)
			ai_action.perform(self)
