extends Node2D

class_name CellMap

var map_width: int = 60
var map_height: int = 60
var astar: AStar2D = AStar2D.new()
# var id_table: Dictionary = {} # Vector2i -> int0
# var node_to_cell_pos_map: Dictionary = {} # Node -> Vector2i (position in cell units)
# var cell_pos_to_cell_node_map: Dictionary = {} # Vector2i (position in cell units) -> Node belonging to 'cell' group
const CELL_SIZE: Vector2i = Vector2i(32, 32)
const S_Cell: PackedScene = preload("res://scenes/Cell.tscn")
const S_Player: PackedScene = preload("res://scenes/Player.tscn")
const S_Mob: PackedScene = preload("res://scenes/Mob.tscn")
@onready var first_build: bool = true
@onready var mobs: Node = $Mobs
@onready var terrain: Node = $Terrain
var player: Actor
var player_mrpas: MRPAS
var ready_for_player_input: bool = true
var turn: int = 0
var floor: int = 1

var cells_seen: Array[Vector2i] = []

func world_to_coords(pos: Vector2) -> Vector2i:
	# assert(pos.x % CELL_SIZE.x == 0 and pos.y % CELL_SIZE.y == 0, "{p} can't fit on the grid!".format({'p': pos}))
	# pos.x / int(pos.x) != 1 might work?  look into this later
	return Vector2i(floor(pos.x / CELL_SIZE.x), floor(pos.y / CELL_SIZE.y))

func coords_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * CELL_SIZE.x, pos.y * CELL_SIZE.y)

func get_nodes_at_coords(pos: Vector2i) -> Array:
	return (mobs.get_children() + terrain.get_children()).filter(func(mob):
		var m_pos = world_to_coords(mob.position)
		return m_pos.x == pos.x && m_pos.y == pos.y)

func get_astar_point_coords() -> Dictionary: # Given that we are only working in coordinates (i.e. Vector2i) there is no reason to even consider using Vector2s
	""" Returns a dictionary of every coordinate (Vector2i) -> astar id (int) """
	var coords_to_id_map: Dictionary = {}
	var point_ids: PackedInt64Array = astar.get_point_ids()
	for id in point_ids:
		var p: Vector2 = astar.get_point_position(id)
		var p_v2i: Vector2i = Vector2i(p.x, p.y)
#		assert(p.x / int(p.x) == 1 and p.y / int(p.y) == 1, "AStar2D point id {id} has decimals!  This point was positioned incorrectly and will not work on a grid!".format({'id': id}))
		coords_to_id_map[p_v2i] = id
	return coords_to_id_map

func get_adjacent_cells_nsew(astar_point_coords: Dictionary, pos: Vector2i) -> Array[Vector2i]:
	var adj_cells: Array[Vector2i] = []
	var adj_positions: Array[Vector2i] = [
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, 1)
		]
	var valid_coords: Array = astar_point_coords.keys()
	for adj_pos in adj_positions:
		if adj_pos+pos in valid_coords:
			adj_cells.append(adj_pos+pos)
	return adj_cells

func generate_astar() -> void:
	astar.clear()

	for t in terrain.get_children():
		var new_point_id: int = astar.get_available_point_id()
		astar.add_point(new_point_id, world_to_coords(t.position))
		if t.blocks_movement: # solid walls and stuff
			astar.set_point_disabled(new_point_id)

	var terrain_map: Dictionary = get_astar_point_coords()
	for coords in terrain_map.keys():
		for adj_pos in get_adjacent_cells_nsew(terrain_map, coords):
			astar.connect_points(terrain_map[coords], terrain_map[adj_pos])
			# do i need to swap these keys/value aorund?
		#for adj_pos in get_adjacent_cells_diag(pos):
			#astar.connect_points(get_cell_id(pos), get_cell_id(adj_pos), 1.41)

class BinarySpacePartition:
	var rect: Rect2i
	var first: BinarySpacePartition
	var second: BinarySpacePartition
	var room: Rect2i
	var has_room: bool
	# var cell_map: CellMap
	const MINIMUM_WIDTH: int = 4
	const MINIMUM_HEIGHT: int = 4

	func _init(rect: Rect2i) -> void:
		self.rect = rect

	func get_leaves() -> Array: # Array[BinarySpacePartition] return doesn't work :)
		if first and second:
			return first.get_leaves() + second.get_leaves()
		else:
			return [self]

	func recursively_make_tree(depth: int, horizontal: bool) -> void:
		const LOWER_RANGE: float = 0.4
		const UPPER_RANGE: float = 0.6
		var split_percent: float = randf_range(LOWER_RANGE, UPPER_RANGE)

		if horizontal:
			if depth > 0:
				var split_height: int = split_percent * rect.size.y
				first = BinarySpacePartition.new(Rect2i(rect.position.x, rect.position.y, rect.size.x, split_height))
				second = BinarySpacePartition.new(Rect2i(rect.position.x, rect.position.y+split_height, rect.size.x, rect.size.y-split_height))
				first.recursively_make_tree(depth-1, not horizontal)
				second.recursively_make_tree(depth-1, not horizontal)
		else:
			if depth > 0:
				var split_width: int = split_percent * rect.size.x
				first = BinarySpacePartition.new(Rect2(rect.position.x, rect.position.y, split_width, rect.size.y))
				second = BinarySpacePartition.new(Rect2(rect.position.x+split_width, rect.position.y, rect.size.x-split_width, rect.size.y))
				first.recursively_make_tree(depth-1, not horizontal)
				second.recursively_make_tree(depth-1, not horizontal)

	func get_room_center() -> Vector2:
		# Returns the center of the BinarySpacePartition's room if it has one.  Expects to be called only on BinarySpacePartitions we know have a room.
		# Returned Vector2 will be in "grid/tile positioning", not absolute

		var raw_center = room.get_center()

		return Vector2i(int(raw_center.x), int(raw_center.y))

	'''
	func make_room_from_chunk() -> void:
		# makes the entire chunk into a room
		# FIXME: something i did when refactoring and changing how tunnels are made broke this function
		var room_color: Color = Color(randf(), randf(), randf())
		room = Rect2(rect.position.x+1, rect.end.x-1, rect.position.y+1, rect.end.y-1) # Save our room info for later
		has_room = true
		for x in range(rect.position.x+1, rect.end.x-1):
			for y in range(rect.position.y+1, rect.end.y-1):
				var c: Cell = cell_map.cell_pos_to_node_map[Vector2i(x, y)]
				c.set_cell_type(Cell.CellType.FLOOR)
				c.get_node('Bg').modulate = room_color
'''

func make_room_in_bsp(bsp: BinarySpacePartition) -> void:
	# places a room randomly inside our boundries defined by rect
	if bsp.rect.size.x <= bsp.MINIMUM_WIDTH or bsp.rect.size.y <= bsp.MINIMUM_HEIGHT:
		print_debug('chunk with rect of %s too small to generate a room in!' % [bsp.rect])
		return # don't bother, this chunk is too small
#		var room_color: Color = Color(randf(), randf(), randf())
	var new_room_size_x: int = bsp.MINIMUM_WIDTH + randi() % int(bsp.rect.size.x - bsp.MINIMUM_WIDTH + 1) # minimum_width <= rect.size.x <= rect.size.x
	var new_room_size_y: int = bsp.MINIMUM_HEIGHT + randi() % int(bsp.rect.size.y - bsp.MINIMUM_HEIGHT + 1) # +1 to avoid % by zero
	var new_room_position_x: int = bsp.rect.position.x + int(bsp.rect.size.x - new_room_size_x)
	var new_room_position_y: int = bsp.rect.position.y + int(bsp.rect.size.y - new_room_size_y)
	var new_room: Rect2 = Rect2(new_room_position_x, new_room_position_y, new_room_size_x, new_room_size_y)
	bsp.room = new_room # Save our room info for later
	bsp.has_room = true
#		print_debug('room %s' % [room] )

	var all_cells: Array[Node] = terrain.get_children()
	# var cells: Array[Node] = terrain.get_children()
	for x in range(new_room.position.x+1, new_room.end.x-1):
		for y in range(new_room.position.y+1, new_room.end.y-1): # -/+1 to give us space for walls
			var c: Cell = all_cells.filter(func(e): return world_to_coords(e.position) == Vector2i(x, y))[0] # there !!!should!!! be only one cell in terrain by position...
			c.set_cell_type(Cell.CellType.FLOOR)

func dig_tunnel(start_x: int, start_y: int, finish_x: int, finish_y) -> void:
	if randi() % 2 == 0:
		create_h_tunnel(start_x, finish_x, start_y)
		create_v_tunnel(start_y, finish_y, finish_x)
	else:
		create_v_tunnel(start_y, finish_y, start_x)
		create_h_tunnel(start_x, finish_x, finish_y)

func create_h_tunnel(x1: int, x2: int, y: int) -> void:
	var all_cells: Array[Node] = terrain.get_children()
	for x in range(min(x1, x2), max(x1, x2) + 1):
		var c: Cell = all_cells.filter(func(e): return world_to_coords(e.position) == Vector2i(x, y))[0] # there !!!should!!! be only one cell in terrain by position...
		c.set_cell_type(Cell.CellType.FLOOR)

func create_v_tunnel(y1: int, y2: int, x: int) -> void:
	var all_cells: Array[Node] = terrain.get_children()
	for y in range(min(y1, y2), max(y1, y2) + 1):
		var c: Cell = all_cells.filter(func(e): return world_to_coords(e.position) == Vector2i(x, y))[0] # there !!!should!!! be only one cell in terrain by position...
		c.set_cell_type(Cell.CellType.FLOOR)

func connect_rooms_with_tunnels(tree_root: BinarySpacePartition) -> void:
	var leaves: Array = tree_root.get_leaves()

	assert(len(leaves) >= 2)

	for idx in range(len(leaves)-1):
		var start: Vector2 = leaves[idx].get_room_center()
		var finish: Vector2 = leaves[idx+1].get_room_center()
		dig_tunnel(start.x, start.y, finish.x, finish.y)

func generate_map() -> BinarySpacePartition:
	if first_build:
		for x in range(map_width):
			for y in range(map_height):
				var c: Cell = S_Cell.instantiate()
				c.position = Vector2i(x, y) * CELL_SIZE
				c.set_cell_type(Cell.CellType.WALL)
				terrain.add_child(c)
		first_build = false
	else:
		# Recycle our Node cells instead of deleting and respawning them
		for c in get_children():
			c.set_cell_type(Cell.CellType.WALL)

	var root: BinarySpacePartition = BinarySpacePartition.new(Rect2i(0, 0, map_width, map_height))

	root.recursively_make_tree(4, randi() % 2 == 0)
	for leaf in root.get_leaves():
		make_room_in_bsp(leaf)
	connect_rooms_with_tunnels(root)

	return root

func populate_map(root: BinarySpacePartition) -> void:
	var p_pos: Vector2i = root.get_leaves()[0].get_room_center()
	spawn_player(p_pos.x, p_pos.y)

	for room in root.get_leaves().slice(1):
		var mob_pos: Vector2i = room.get_room_center()
		spawn_mob(mob_pos.x, mob_pos.y, "guard")

func build_mrpas_from_map() -> MRPAS:
	""" creates a new MRPAS object based on the CellMap and returns it """
	var m = MRPAS.new(Vector2(map_width, map_height))
	# for cell in node_to_cell_pos_map.keys().filter(func(node): return node.is_in_group('cell')):
	for cell in terrain.get_children():
		var cell_pos: Vector2i = world_to_coords(cell.position)
		m.set_transparent(cell_pos, not cell.blocks_movement)
	m.clear_field_of_view()
	return m

func spawn_player(x: int, y: int) -> void:
	""" Places a player somewhere and then updates fov """
	player = S_Player.instantiate()
	player_mrpas = build_mrpas_from_map()
	player.position = coords_to_world(Vector2i(x, y))
	add_child(player)
	player_mrpas.compute_field_of_view(world_to_coords(player.position), 8)
	reveal_map_based_on_fov(player_mrpas)

func spawn_mob(x: int, y: int, mob_key: String) -> void: # should this take in get_astar_point_coords?
	var m = S_Mob.instantiate()
	m.mob_key = mob_key
	m.position = coords_to_world(Vector2i(x, y))
	mobs.add_child(m)
	var point_map: Dictionary = get_astar_point_coords()
	var cid: int = point_map[world_to_coords(m.position)]
	astar.set_point_disabled(cid)
	m.init_mrpas(build_mrpas_from_map())
	m.mortality.connect('died', _on_mob_died)

func _on_mob_died(poor_schmuck: Mob) -> void:
#		poor_schmuck.queue_free()
	poor_schmuck.label.modulate = Color.BLANCHED_ALMOND
	var schmuck_pos: Vector2i = world_to_coords(poor_schmuck.position)
	var point_map: Dictionary = get_astar_point_coords()
	var cell_died_at = point_map[schmuck_pos]
	astar.set_point_disabled(cell_died_at, false)
	HUDSignalBus.emit_signal("new_journal_entry", '{name} has died!'.format({'name': poor_schmuck.actor_name}))

func _unhandled_input(event: InputEvent) -> void:
	var delta_vec: Vector2i
	if event.is_action_pressed("move_north"):
		delta_vec = Vector2i(0, -1)
	elif event.is_action_pressed("move_south"):
		delta_vec = Vector2i(0, 1)
	elif event.is_action_pressed("move_west"):
		delta_vec = Vector2i(-1, 0)
	elif event.is_action_pressed("move_east"):
		delta_vec = Vector2i(1, 0)

	if delta_vec:
		# var astar_state: Dictionary = get_astar_point_coords()
		var player_action: Action = MoveAction.new(player, delta_vec)
		if player_action.possible(self):
			process_turn(player_action)
		else:
			var p_coords: Vector2i = world_to_coords(player.position)
			var potential_victims: = get_nodes_at_coords(p_coords + delta_vec).filter(func(node): return node.is_in_group('mob'))
			if potential_victims:
				var victim: Actor = potential_victims[0] # just grab the first one idc
				player_action = AttackAction.new(player, victim, 5)
				if player_action.possible(self):
					process_turn(player_action) # TODO: re-add I can't do that! messages
			else:
				HUDSignalBus.emit_signal('new_journal_entry', "I can't do that!")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var bsp_tree: BinarySpacePartition = generate_map()
	generate_astar()

	populate_map(bsp_tree)
#	player.connect("new_action", _on_player_new_action)
	HUDSignalBus.emit_signal("new_turn", turn)
	HUDSignalBus.emit_signal("new_floor", floor)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass


func reveal_map_based_on_fov(fov: MRPAS) -> void:
	for n in terrain.get_children():
		var n_coords: Vector2i = world_to_coords(n.position)
		if fov.is_in_view(n_coords):
			n.modulate = Color.WHITE
			n.show()
			if not n_coords in cells_seen:
				cells_seen.append(n_coords)
		elif n_coords in cells_seen:
			n.modulate = Color.DARK_RED
			n.show()
		else:
			n.hide()

func actions_completed() -> void:
	# previously _on_player_action_completed or whatever it was called
	player_mrpas.clear_field_of_view()
	player_mrpas.compute_field_of_view(world_to_coords(player.position), 8)
	turn += 1
	HUDSignalBus.emit_signal('new_turn', turn)
	reveal_map_based_on_fov(player_mrpas)
	ready_for_player_input = true

func process_turn(player_action: Action) -> void:
	ready_for_player_input = false

	var promise: Promise = Promise.new()
	promise.connect('resolved', actions_completed)
	var actions: Array[Action] = []
	actions.append(player_action)
	promise.add_signal(player_action.action_completed)
	
	for mob in mobs.get_children():
		if mob.ai != null and mob.mortality.is_alive():
			var ai_action: Action = mob.ai.get_next_action(self)
			actions.append(ai_action)
			promise.add_signal(ai_action.action_completed)

	for action in actions:
		action.perform(self)
