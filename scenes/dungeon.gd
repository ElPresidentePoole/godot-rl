extends Node2D

const S_Player: PackedScene = preload("res://scenes/player.tscn")
const S_Mob: PackedScene = preload("res://scenes/mob_wizard.tscn")
const S_Cell: PackedScene = preload("res://scenes/cell.tscn")
const S_Gold: PackedScene = preload("res://scenes/gold.tscn")

@onready var mobs: Node = $Mobs
@onready var cellmap: CellMap = $CellMap
@onready var astar: AStar2D = $CellMap.astar
@onready var player: Node2D = $Player
@onready var player_mrpas: MRPAS = cellmap.build_mrpas_from_map()
var player_seen_tiles: Array[Vector2] = [] # TODO
var mob_mrpas_map: Dictionary = {}

func spawn_gold(x: int, y: int) -> void:
	var g = S_Gold.instantiate()
	$Items.add_child(g)
	g.position = Vector2(x, y) * cellmap.CELL_SIZE

func place_player(x: int, y: int) -> void:
	""" Places a player somewhere and then updates fov """
	var p = player
	p.position = Vector2(x, y) * cellmap.CELL_SIZE
	update_player_fov(p.position)

func spawn_mob(x: int, y: int) -> void:
	var m = S_Mob.instantiate()
	m.position = Vector2(x, y) * cellmap.CELL_SIZE
	var cid: int = cellmap.get_cell_id(m.position)
	astar.set_point_disabled(cid)
	mob_mrpas_map[m] = cellmap.build_mrpas_from_map()
	m.connect('request_to_attack', func(perp):
		attack(perp, player))
	m.mortality.connect('died', func(poor_schmuck):
		var cell_died_at = astar.get_closest_point(poor_schmuck.position, true)
		poor_schmuck.queue_free()
		astar.set_point_disabled(cell_died_at, false)
		mob_mrpas_map.erase(poor_schmuck)
		)
	mobs.add_child(m)

func update_mob_fov(m: Node2D) -> void:
	mob_mrpas_map[m].clear_field_of_view()
	mob_mrpas_map[m].compute_field_of_view(cellmap.world_pos_to_cell(m.position), m.VIEW_DISTANCE)

func update_player_fov(new_position: Vector2) -> void:
	""" Calculates the player's current fov and hides/shows mobs and cellmap cells based on it.  This, obviously, causes side effects! 
	Note from future me: What side effects?  We aren't doing functional programming?  Also new_position should WORLD position, not cell map position.
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
	var leaves: Array = cellmap.root.get_leaves()
	var mob_pos: Vector2 = leaves[1].get_room_center()
	spawn_mob(mob_pos.x, mob_pos.y)
	var spawn_room: Vector2 = leaves[0].get_room_center()
	place_player(spawn_room.x, spawn_room.y) # spawn the player last so our FOV stuff hides the mob
	for l in leaves:
		if randf() < 0.5:
			spawn_gold(l.get_room_center().x, l.get_room_center().y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass

func find_mob_by_position(pos: Vector2) -> Node2D:
	for m in mobs.get_children():
		if m.position == pos:
			return m
	return null

func attack(perp: Node2D, victim: Node2D) -> void:
	# TODO: damage based on perp
	victim.mortality.take_damage(1)
	player.hud.log_container.add_entry("{perp} attacks {victim}".format({'perp': perp.mob_name, 'victim': victim.mob_name}))

func process_turn(player_state):
	for m in mobs.get_children():
		if not m.is_queued_for_deletion():
			update_mob_fov(m)
			m.do_turn_behavior(astar, mob_mrpas_map[m], cellmap, player_state)
	update_player_fov(player.position)

func _on_player_request_to_move(dv):
	dv *= cellmap.CELL_SIZE
	var col_point = player.position+dv
	if astar.is_point_disabled(cellmap.get_cell_id(col_point)):
		var mob_bumped_into = find_mob_by_position(col_point)
		if mob_bumped_into:
			attack(player, mob_bumped_into)
			process_turn({ 'new_position': player.position })
			# wait an entire second before allowing us to "move" again, as move's delay is 0.1 seconds
			player.ready_to_move = false
			await get_tree().create_timer(1).timeout
			player.ready_to_move = true
	else:
		process_turn({ 'new_position': player.position+dv })
		player.move(dv)
