extends Node2D

@onready var cellmap: CellMap = $"CellMap"
@onready var astar: AStar2D = cellmap.astar
@onready var player: Actor = $"CellMap/Player"
@onready var player_hud: HUDLayer = $"CellMap/Player/HUDLayer"
@onready var player_mrpas: MRPAS = cellmap.build_mrpas_from_map()
var turn: int = 0
var cells_seen: Array[Vector2i] = []

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

func update_player_fov() -> void:
	player_mrpas.clear_field_of_view()
	player_mrpas.compute_field_of_view(cellmap.get_cell_pos(player), 8)
	
	for n in cellmap.terrain.get_children():
		if player_mrpas.is_in_view(cellmap.get_cell_pos(n)):
			n.modulate = Color.WHITE
			n.show()
			if not cellmap.get_cell_pos(n) in cells_seen:
				cells_seen.append(cellmap.get_cell_pos(n))
		elif cellmap.get_cell_pos(n) in cells_seen:
			n.modulate = Color.DARK_RED
			n.show()
		else:
			n.hide()

func player_perform_action(action):
	action.perform(self)
	
	for mob in $CellMap/Mobs.get_children():
		if mob.ai != null:
			var ai_action: Action = mob.ai.get_next_action(self)
			ai_action.perform(self)
	
	turn += 1
	player_hud.turn_label.text = "Turn: {t}".format({'t': turn})
	update_player_fov()
