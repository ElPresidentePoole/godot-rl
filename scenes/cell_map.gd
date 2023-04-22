extends Node2D

class_name CellMap

# signal map_generated

var astar: AStar2D = AStar2D.new()
var id_table: Dictionary = {} # Vector2 -> int
var node_table: Dictionary = {} # Vector2 (position) -> Node2D
var root: Chunk = null
#var occupied: Array[Vector2]
const CELL_SIZE: Vector2 = Vector2(32, 32)
const S_Cell: PackedScene = preload("res://scenes/cell.tscn")

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

func get_cell_id(cell: Vector2) -> int:
	""" Gets the id of a cell from its Vector2, or assigns it an id and returns the new id """
	if not cell in id_table:
		id_table[cell] = astar.get_available_point_id()
	return id_table[cell]

func get_adjacent_cells_diag(pos: Vector2) -> Array[Vector2]:
	var adj_cells: Array[Vector2] = []
	var adj_positions: Array[Vector2] = [
		Vector2(-1, -1) * CELL_SIZE,
		Vector2(1, -1) * CELL_SIZE,
		Vector2(-1, 1) * CELL_SIZE,
		Vector2(1, 1) * CELL_SIZE
		]
	for adj_pos in adj_positions:
		if adj_pos+pos in node_table:
			adj_cells.append(adj_pos+pos)
	return adj_cells

func get_adjacent_cells_nsew(pos: Vector2) -> Array[Vector2]:
	var adj_cells: Array[Vector2] = []
	var adj_positions: Array[Vector2] = [
		#Vector2(-1, -1) * CELL_SIZE,
		Vector2(0, -1) * CELL_SIZE,
		#Vector2(1, -1) * CELL_SIZE,
		Vector2(-1, 0) * CELL_SIZE,
		Vector2(1, 0) * CELL_SIZE,
		#Vector2(-1, 1) * CELL_SIZE,
		Vector2(0, 1) * CELL_SIZE,
		#Vector2(1, 1) * CELL_SIZE
		]
	for adj_pos in adj_positions:
		if adj_pos+pos in node_table:
			adj_cells.append(adj_pos+pos)
	return adj_cells

func populate_node_table() -> void:
	for cell in get_children():
		node_table[cell.position] = cell

func generate_astar() -> void:
	astar.clear()

	for pos in node_table:
		astar.add_point(get_cell_id(pos), pos)
		if node_table[pos].blocks_movement: # solid walls and stuff
			astar.set_point_disabled(get_cell_id(pos))

	for pos in node_table:
		for adj_pos in get_adjacent_cells_nsew(pos):
			astar.connect_points(get_cell_id(pos), get_cell_id(adj_pos))
		#for adj_pos in get_adjacent_cells_diag(pos):
			#astar.connect_points(get_cell_id(pos), get_cell_id(adj_pos), 1.41)

class Chunk: # this should probably be called BinaryNode or Chunk or something else
	var _rect: Rect2
	var first: Chunk
	var second: Chunk
	var room: Rect2
	var has_room: bool
	var _cell_map: CellMap
	const MINIMUM_WIDTH: int = 4
	const MINIMUM_HEIGHT: int = 4

	func _init(cell_map: CellMap, rect: Rect2) -> void:
		self._rect = rect
		self._cell_map = cell_map

	func get_leaves() -> Array: # Array[Chunk] return doesn't work :)
		if first and second:
			return first.get_leaves() + second.get_leaves()
		else:
			return [self]

	func build_rooms(depth: int, horizontal: bool) -> void:
		const LOWER_RANGE: float = 0.4
		const UPPER_RANGE: float = 0.6
		var split_percent: float = randf_range(LOWER_RANGE, UPPER_RANGE)

		if horizontal:
			if depth > 0:
				var split_height: int = split_percent * _rect.size.y
				first = Chunk.new(_cell_map, Rect2(_rect.position.x, _rect.position.y, _rect.size.x, split_height))
				second = Chunk.new(_cell_map, Rect2(_rect.position.x, _rect.position.y+split_height, _rect.size.x, _rect.size.y-split_height))
				first.build_rooms(depth-1, not horizontal)
				second.build_rooms(depth-1, not horizontal)
			else:
				make_room_in_chunk()
		else:
			if depth > 0:
				var split_width: int = split_percent * _rect.size.x
				first = Chunk.new(_cell_map, Rect2(_rect.position.x, _rect.position.y, split_width, _rect.size.y))
				second = Chunk.new(_cell_map, Rect2(_rect.position.x+split_width, _rect.position.y, _rect.size.x-split_width, _rect.size.y))
				first.build_rooms(depth-1, not horizontal)
				second.build_rooms(depth-1, not horizontal)
			else:
				make_room_in_chunk()

	func connect_rooms_with_tunnels() -> void:
		# TODO: doesn't do as good of a job connecting all the rooms as i've expected...
		# Should we keep track of the middle of a tunnel, and then connect those together instead of the center of a chunk?

		var leaves: Array = get_leaves()

		assert(len(leaves) >= 2)

		for idx in range(len(leaves)-1):
			var start: Vector2 = leaves[idx].get_room_center()
			var finish: Vector2 = leaves[idx+1].get_room_center()
			dig_tunnel(start.x, start.y, finish.x, finish.y)

		# if first.has_room and second.has_room: # Both of these should have has_room == true at the same time, checking both is just a "it looks better" thing over just "if first.has_room:"
			# print_debug(first.room, second.room)
			# var center_first: Vector2 = first.get_room_center()
			# var center_second: Vector2 = second.get_room_center()
			# dig_tunnel(center_first.x, center_first.y, center_second.x, center_second.y)
		# else:
			# print_debug('no rooms')
			# var center_first: Vector2 = first._rect.get_center()
			# var center_second: Vector2 = second._rect.get_center()
			# dig_tunnel(center_first.x, center_first.y, center_second.x, center_second.y)
			# first.connect_rooms_with_tunnels()
			# second.connect_rooms_with_tunnels()

	func get_room_center() -> Vector2:
		# Returns the center of the Chunk's room if it has one.  Expects to be called only on Chunks we know have a room.
		# Returned Vector2 will be in "grid/tile positioning", not absolute

		var raw_center = room.get_center()

		return Vector2(int(raw_center.x), int(raw_center.y))

	func make_room_from_chunk() -> void:
		# makes the entire chunk into a room
		# FIXME: something i did when refactoring and changing how tunnels are made broke this function
		var room_color: Color = Color(randf(), randf(), randf())
		room = Rect2(_rect.position.x+1, _rect.end.x-1, _rect.position.y+1, _rect.end.y-1) # Save our room info for later
		has_room = true
		for x in range(_rect.position.x+1, _rect.end.x-1):
			for y in range(_rect.position.y+1, _rect.end.y-1):
				var c: Cell = _cell_map.node_table[Vector2(x, y) * CELL_SIZE]
				c.set_cell_type(Cell.CellType.FLOOR)
				c.get_node('Bg').modulate = room_color

	func make_room_in_chunk() -> void: # XXX should this go here, or in CellMap?
		# places a room randomly inside our boundries defined by _rect
		if _rect.size.x <= MINIMUM_WIDTH or _rect.size.y <= MINIMUM_HEIGHT:
			print_debug('chunk with _rect of %s too small to generate a room in!' % [_rect])
			return # don't bother, this chunk is too small
		var room_color: Color = Color(randf(), randf(), randf())
		var new_room_size_x: int = MINIMUM_WIDTH + randi() % int(_rect.size.x - MINIMUM_WIDTH + 1) # minimum_width <= _rect.size.x <= _rect.size.x
		var new_room_size_y: int = MINIMUM_HEIGHT + randi() % int(_rect.size.y - MINIMUM_HEIGHT + 1) # +1 to avoid % by zero
		var new_room_position_x: int = _rect.position.x + int(_rect.size.x - new_room_size_x)
		var new_room_position_y: int = _rect.position.y + int(_rect.size.y - new_room_size_y)
		var new_room: Rect2 = Rect2(new_room_position_x, new_room_position_y, new_room_size_x, new_room_size_y)
		room = new_room # Save our room info for later
		has_room = true
		print_debug('room %s' % [room] )
		for x in range(new_room.position.x+1, new_room.end.x-1):
			for y in range(new_room.position.y+1, new_room.end.y-1): # -/+1 to give us space for walls
				var c: Cell = _cell_map.node_table[Vector2(x, y) * CELL_SIZE]
				c.set_cell_type(Cell.CellType.FLOOR)
				c.get_node('Bg').modulate = room_color

	func dig_tunnel(start_x: int, start_y: int, finish_x: int, finish_y) -> void:
		if randi() % 2 == 0:
			create_h_tunnel(start_x, finish_x, start_y)
			create_v_tunnel(start_y, finish_y, finish_x)
		else:
			create_v_tunnel(start_y, finish_y, start_x)
			create_h_tunnel(start_x, finish_x, finish_y)

	func create_h_tunnel(x1: int, x2: int, y: int) -> void:
		for x in range(min(x1, x2), max(x1, x2) + 1):
			var pos: Vector2 = Vector2(x, y) * CELL_SIZE
			var c: Cell = _cell_map.node_table[pos]
			c.set_cell_type(Cell.CellType.FLOOR)

	func create_v_tunnel(y1: int, y2: int, x: int) -> void:
		for y in range(min(y1, y2), max(y1, y2) + 1):
			var pos: Vector2 = Vector2(x, y) * CELL_SIZE
			var c: Cell = _cell_map.node_table[pos]
			c.set_cell_type(Cell.CellType.FLOOR)

func generate_map() -> void:
	var map_width: int = 60
	var map_height: int = 60

	for x in range(map_width):
		for y in range(map_height):
			var c: Cell = S_Cell.instantiate()
			c.position = Vector2(x, y) * CELL_SIZE
			c.set_cell_type(Cell.CellType.WALL)
			add_child(c)

	populate_node_table()

	root = Chunk.new(self, Rect2(0, 0, map_width, map_height))

	root.build_rooms(4, randi() % 2 == 0)
	root.connect_rooms_with_tunnels()

# Called when the node enters the scene tree for the first time.
func _ready():
	generate_map()
	generate_astar()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
