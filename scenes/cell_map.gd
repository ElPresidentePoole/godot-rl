extends Node2D

class_name CellMap

var map_width: int = 60
var map_height: int = 60
var astar: AStar2D = AStar2D.new()
var id_table: Dictionary = {} # Vector2i -> int
# should I set up a add_tree/remove_from_tree signal for this map below?
var node_to_cell_pos_map: Dictionary = {} # Node -> Vector2i (position in cell units)
var cell_pos_to_cell_node_map: Dictionary = {} # Vector2i (position in cell units) -> Node belonging to 'cell' group
var root: BinarySpacePartition = null
@onready var first_build: bool = true
#var occupied: Array[Vector2]
const CELL_SIZE: Vector2i = Vector2i(32, 32)
const S_Cell: PackedScene = preload("res://scenes/cell.tscn")

@onready var player: Actor = $Player

func world_pos_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(pos.x / CELL_SIZE.x, pos.y / CELL_SIZE.y)

func cell_pos_to_world(pos: Vector2i) -> Vector2:
	return Vector2(pos.x * CELL_SIZE.x, pos.y * CELL_SIZE.y)

func get_nodes_at_cell_pos(pos: Vector2i) -> Array:
	return node_to_cell_pos_map.keys().filter(func(node):
		return node_to_cell_pos_map[node] == pos)

func get_cell_pos(n: Node) -> Vector2i:
	return node_to_cell_pos_map[n]

func add_to_map(node: Node) -> void:
	""" Makes an entry in node_to_cell_pos_map (and cell_pos_to_cell_node_map if necessary!) for the node """
	var cell_pos: Vector2i = world_pos_to_cell(node.position)
	node_to_cell_pos_map[node] = cell_pos
	if node.is_in_group('cell'):
		assert(not cell_pos in cell_pos_to_cell_node_map, 'Multiple nodes of group "cell" occupying same cell position! {pos}'.format({'pos': cell_pos}))
		cell_pos_to_cell_node_map[cell_pos] = node

func remove_from_map(node: Node) -> void:
	var cell_pos: Vector2i = node_to_cell_pos_map[node]
	if node.is_in_group('cell'):
		cell_pos_to_cell_node_map.erase(cell_pos)
	node_to_cell_pos_map.erase(node)

#func is_occupied(pos: Vector2) -> bool:
	#assert(pos in id_table) # Sanity check to make sure a position is in our valid cells
	#return pos in occupied

#func set_occupied(pos: Vector2) -> void:
	#assert(pos in id_table) # Sanity check to make sure a position is in our valid cells
	#if not pos in occupied:
		#occupied.append(pos)

#func set_unoccupied(pos: Vector2) -> void:
	#assert(pos in id_table) # Sanity check to make sure a position is in our valid cells
	#var idx = occupied.find(pos)
	#if idx != -1:
		#occupied.remove_at(idx)

func get_cell_id(cell: Vector2i) -> int:
	""" Gets the id of a cell from its Vector2, or assigns it an id and returns the new id """
	if not cell in id_table:
		id_table[cell] = astar.get_available_point_id()
#		print_debug(cell, " not in id_table, added new cell as id ", id_table[cell])
	return id_table[cell]

'''
func get_adjacent_cells_diag(pos: Vector2) -> Array[Vector2]:
	var adj_cells: Array[Vector2] = []
	var adj_positions: Array[Vector2i] = [
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(1, 1)
		]
	for adj_pos in adj_positions:
		if adj_pos+pos in cell_pos_to_node_map:
			adj_cells.append(adj_pos+pos)
	return adj_cells
'''

func get_adjacent_cells_nsew(pos: Vector2i) -> Array[Vector2i]:
	var adj_cells: Array[Vector2i] = []
	var adj_positions: Array[Vector2i] = [
		Vector2i(0, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, 1)
		]
	for adj_pos in adj_positions:
		if adj_pos+pos in cell_pos_to_cell_node_map:
			adj_cells.append(adj_pos+pos)
	return adj_cells

func generate_astar() -> void:
	astar.clear()

	for pos in cell_pos_to_cell_node_map:
		astar.add_point(get_cell_id(pos), pos)
		if cell_pos_to_cell_node_map[pos].blocks_movement: # solid walls and stuff
			astar.set_point_disabled(get_cell_id(pos))

	for pos in cell_pos_to_cell_node_map:
		for adj_pos in get_adjacent_cells_nsew(pos):
			astar.connect_points(get_cell_id(pos), get_cell_id(adj_pos))
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
	for x in range(new_room.position.x+1, new_room.end.x-1):
		for y in range(new_room.position.y+1, new_room.end.y-1): # -/+1 to give us space for walls
			var c: Cell = cell_pos_to_cell_node_map[Vector2i(x, y)]
			c.set_cell_type(Cell.CellType.FLOOR)

func dig_tunnel(start_x: int, start_y: int, finish_x: int, finish_y) -> void:
	if randi() % 2 == 0:
		create_h_tunnel(start_x, finish_x, start_y)
		create_v_tunnel(start_y, finish_y, finish_x)
	else:
		create_v_tunnel(start_y, finish_y, start_x)
		create_h_tunnel(start_x, finish_x, finish_y)

func create_h_tunnel(x1: int, x2: int, y: int) -> void:
	for x in range(min(x1, x2), max(x1, x2) + 1):
		var pos: Vector2i = Vector2i(x, y)
		var c: Cell = cell_pos_to_cell_node_map[pos]
		c.set_cell_type(Cell.CellType.FLOOR)

func create_v_tunnel(y1: int, y2: int, x: int) -> void:
	for y in range(min(y1, y2), max(y1, y2) + 1):
		var pos: Vector2i = Vector2i(x, y)
		var c: Cell = cell_pos_to_cell_node_map[pos]
		c.set_cell_type(Cell.CellType.FLOOR)

func connect_rooms_with_tunnels(tree_root: BinarySpacePartition) -> void:
	var leaves: Array = tree_root.get_leaves()

	assert(len(leaves) >= 2)

	for idx in range(len(leaves)-1):
		var start: Vector2 = leaves[idx].get_room_center()
		var finish: Vector2 = leaves[idx+1].get_room_center()
		dig_tunnel(start.x, start.y, finish.x, finish.y)

func generate_map() -> void:
	if first_build:
		for x in range(map_width):
			for y in range(map_height):
				var c: Cell = S_Cell.instantiate()
				c.position = Vector2i(x, y) * CELL_SIZE
				c.set_cell_type(Cell.CellType.WALL)
				add_child(c)
				add_to_map(c)
		first_build = false
	else:
		# Recycle our Node cells instead of deleting and respawning them
		for c in get_children():
			c.set_cell_type(Cell.CellType.WALL)

	root = BinarySpacePartition.new(Rect2i(0, 0, map_width, map_height))

	root.recursively_make_tree(4, randi() % 2 == 0)
	for leaf in root.get_leaves():
		make_room_in_bsp(leaf)
	connect_rooms_with_tunnels(root)

	var p_pos: Vector2i = root.get_leaves()[0].get_room_center()
	place_player(p_pos.x, p_pos.y)

func build_mrpas_from_map() -> MRPAS:
	""" creates a new MRPAS object based on the CellMap and returns it """
	var m = MRPAS.new(Vector2(map_width, map_height))
	for cell in node_to_cell_pos_map.keys().filter(func(node): return node.is_in_group('cell')):
		var cell_pos: Vector2i = node_to_cell_pos_map[cell]
		m.set_transparent(cell_pos, not node_to_cell_pos_map[cell_pos].blocks_movement)
	m.clear_field_of_view()
	return m

func place_player(x: int, y: int) -> void:
	""" Places a player somewhere and then updates fov """
	player.position = cell_pos_to_world(Vector2i(x, y))
	node_to_cell_pos_map[player] = Vector2i(x, y)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_map(player)
	generate_map()
	generate_astar()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass
