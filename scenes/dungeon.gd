extends Node2D

const S_Player: PackedScene = preload("res://scenes/player.tscn")
const S_Mob: PackedScene = preload("res://scenes/mob.tscn")
const S_Cell: PackedScene = preload("res://scenes/cell.tscn")
const S_Gold: PackedScene = preload("res://scenes/gold.tscn")
const S_Gem: PackedScene = preload("res://scenes/gem.tscn")
const S_VisualProjectile: PackedScene = preload("res://scenes/visualprojectile.tscn")

@onready var mobs: Node = $Mobs
@onready var items: Node = $Items
@onready var cellmap: CellMap = $CellMap
@onready var astar: AStar2D = $CellMap.astar
@onready var player: Node2D = $Player
#@onready var player_log: LogContainer = $Player/HUDLayer/LogContainer
@onready var player_mrpas: MRPAS = cellmap.build_mrpas_from_map()
var player_seen_tiles: Array[Vector2] = [] # TODO
var mob_mrpas_map: Dictionary = {}
@onready var turn_count: int = 0

func visualize_projectile(from: Vector2, to: Vector2) -> void:
	""" spawns a node to go from "from" to "to".  uses absolute positioning! """
	"""
	# XXX: should astar be using cell map position or absolute?  i feel like making the positioning "types" more consistent would be a good refactor...
	var from_cid: int = astar.get_closest_point(from, true)
	var to_cid: int = astar.get_closest_point(to, true)
	# HACK: excuse me sir i need to enable your point
	astar.set_point_disabled(to_cid, false)
	var path = astar.get_point_path(from_cid, to_cid)
	astar.set_point_disabled(to_cid, true)
	print_debug('asdf' , path, ' from ' , from)
	if len(path) > 1:
		var proj: Node2D = S_VisualProjectile.instantiate()
		proj.path = path
		add_child(proj)
		await proj.tree_exiting
	"""
	var proj: Node2D = S_VisualProjectile.instantiate()
	proj.position = from
	proj.dest = to
	add_child.call_deferred(proj)
	await proj.tree_exiting
	
func spawn_gem(x: int, y: int) -> void:
	var g = S_Gem.instantiate()
	$Items.add_child(g)
	# g.hide() # I could just have update_player_fov wait for this to spawn first but shouldn't these be hidden at first by default anyways?
	g.position = Vector2(x, y) * cellmap.CELL_SIZE

func spawn_gold(x: int, y: int) -> void:
	var g = S_Gold.instantiate()
	$Items.add_child(g)
	# g.hide() # I could just have update_player_fov wait for this to spawn first but shouldn't these be hidden at first by default anyways?
	g.position = Vector2(x, y) * cellmap.CELL_SIZE

func place_player(x: int, y: int) -> void:
	""" Places a player somewhere and then updates fov """
	player.position = Vector2(x, y) * cellmap.CELL_SIZE

func spawn_mob(x: int, y: int, mob_key: String) -> void:
	var m = S_Mob.instantiate()
	m.mob_key = mob_key
	mobs.add_child(m)
	m.position = Vector2(x, y) * cellmap.CELL_SIZE
	var cid: int = cellmap.get_cell_id(m.position)
	astar.set_point_disabled(cid)
	mob_mrpas_map[m] = cellmap.build_mrpas_from_map()
	m.connect('perform_game_action', _on_perform_game_action)
	m.mortality.connect('died', func(poor_schmuck):
		var cell_died_at = astar.get_closest_point(poor_schmuck.position, true)
#		poor_schmuck.queue_free()
		poor_schmuck.label.modulate = Color.BLANCHED_ALMOND
		astar.set_point_disabled(cell_died_at, false)
		mob_mrpas_map.erase(poor_schmuck)
		player.hud.log_container.add_entry('{name} has died!'.format({'name': poor_schmuck.mob_name}))
		)

func update_mob_fov(m: Node2D) -> void:
	mob_mrpas_map[m].clear_field_of_view()
	mob_mrpas_map[m].compute_field_of_view(cellmap.world_pos_to_cell(m.position), m.vision_range)

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
	for i in items.get_children():
		var item_cell_pos: Vector2 = cellmap.world_pos_to_cell(i.position)
		if player_mrpas.is_in_view(item_cell_pos):
			i.show()
		else:
			i.hide()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var leaves: Array = cellmap.root.get_leaves()
	var spawn_room: Vector2 = leaves[0].get_room_center()
	place_player(spawn_room.x, spawn_room.y) # spawn the player last so our FOV stuff hides the mob
	for l in leaves:
		if randf() < 0.15:
			# +1/-2 to account for walls
			var gx = l.room.position.x + 1 + randi() % int(l.room.size.x - 2)
			var gy = l.room.position.y + 1 + randi() % int(l.room.size.y - 2)
			spawn_gem(gx, gy)
		if randf() < 0.35:
			# +1/-2 to account for walls
			var gx = l.room.position.x + 1 + randi() % int(l.room.size.x - 2)
			var gy = l.room.position.y + 1 + randi() % int(l.room.size.y - 2)
			spawn_gold(gx, gy)
		if randf() < 0.5:
			var gx = l.room.position.x + 1 + randi() % int(l.room.size.x - 2)
			var gy = l.room.position.y + 1 + randi() % int(l.room.size.y - 2)
			spawn_mob(gx, gy, ['wizard', 'officer', 'guard'][randi() % 3])
	update_player_fov(player.position)
	player.hud.turn_label.text = 'Turn: {t}'.format({'t': turn_count})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta) -> void:
	pass

func find_mob_by_position(pos: Vector2) -> Node2D:
	for m in mobs.get_children():
		if m.position == pos:
			return m
	return null

func attack(perp: Node2D, victim: Node2D) -> void:
	victim.mortality.take_damage(perp.weapon.attack_damage)
	player.hud.log_container.add_entry("{perp} {verb} {victim} for {amount} damage.".format({'perp': perp.mob_name, 'verb': perp.weapon.attack_verb, 'victim': victim.mob_name, 'amount': perp.weapon.attack_damage}))
	# TODO: attack_sound should probably be a property of Weapon.gd
	perp.attack_sound.play()
#	await visualize_projectile(perp.position, victim.position)

func process_turn(player_state):
	for m in mobs.get_children():
		if not m.is_queued_for_deletion() and m.mortality.is_alive():
			m.ready_to_act = false
			update_mob_fov(m)
			m.do_turn_behavior(astar, mob_mrpas_map[m], cellmap, player_state, player)
			m.ready_to_act = true
	update_player_fov(player_state['new_position'])
	turn_count += 1
	player.hud.turn_label.text = 'Turn: {t}'.format({'t': turn_count})

#func _on_player_request_to_move(dv):
#	dv *= cellmap.CELL_SIZE
#	var col_point = player.position+dv
#	if astar.is_point_disabled(cellmap.get_cell_id(col_point)):
#		var mob_bumped_into = find_mob_by_position(col_point)
#		if mob_bumped_into:
#			attack(player, mob_bumped_into)
#			process_turn({ 'new_position': player.position })
#			# wait an entire second before allowing us to "move" again, as move's delay is 0.1 seconds
#			player.ready_to_move = false
#			await get_tree().create_timer(0.5).timeout
#			player.ready_to_move = true
#	else:
#		player.move(dv)
#		process_turn({ 'new_position': player.position+dv })
#
#
#func _on_player_fire_at_nearest_mob():
#	# TODO: range
#	if player.ready_to_move:
#		var mobs_to_distance_map: Dictionary = {}
#		for m in mobs.get_children():
#			if player_mrpas.is_in_view(cellmap.world_pos_to_cell(m.position)):
#				mobs_to_distance_map[m] = len(astar.get_point_path(astar.get_closest_point(m.position, true), astar.get_closest_point(player.position, true)))
#		if len(mobs_to_distance_map) > 0:
#			var closest_mob = mobs_to_distance_map.keys()[0]
#			for m in mobs_to_distance_map:
#				if mobs_to_distance_map[m] < mobs_to_distance_map[closest_mob]:
#					closest_mob = m
#			if mobs_to_distance_map[closest_mob] <= player.weapon.attack_range+1:
#				attack(player, closest_mob)
#				process_turn({'new_position': player.position})
#			else:
#				player.hud.log_container.add_entry('Out of range!')
#		else:
#			player.hud.log_container.add_entry('No one in sight!')


func _on_perform_game_action(action, data) -> void:
	if data['actor'] == player and (not player.ready_to_act or mobs.get_children().any(func(m): not m.ready_to_act)):
		return
	var action_successful: bool = false
	if action == GameAction.Actions.ATTACK:
		var rof: int = data['rof'] if 'rof' in data else 1
		data['actor'].ready_to_act = false
		for _bang in range(rof):
			attack(data['actor'], data['victim']) # FIXME: rof > 1 means we're playing the audio for it a lot and it gets loud
		for _bang in range(rof):
			await visualize_projectile(data['actor'].position, data['victim'].position)
			if rof > 1: await get_tree().create_timer(0.1).timeout
		data['actor'].ready_to_act = true
		# "Invalid set index 'ready_to_act' (on base: 'previously freed') with value of type 'bool'
		action_successful = true
	elif action == GameAction.Actions.MOVE:
		var pos_final: Vector2 = data['actor'].position + cellmap.cell_pos_to_world(data['dv'])
		if astar.is_point_disabled(astar.get_closest_point(pos_final, true)): # TODO: may need to check if the points are connected too!
			player.hud.log_container.add_entry("I can't move there!")
		else:
			data['actor'].ready_to_act = false
			await data['actor'].move(astar, cellmap, pos_final)
			data['actor'].ready_to_act = true
			action_successful = true
	elif action == GameAction.Actions.AIM:
		var mobs_to_distance_map: Dictionary = {}
		for m in mobs.get_children():
			if player_mrpas.is_in_view(cellmap.world_pos_to_cell(m.position)):
				mobs_to_distance_map[m] = len(astar.get_point_path(astar.get_closest_point(m.position, true), astar.get_closest_point(player.position, true)))
		if len(mobs_to_distance_map) > 0:
			var closest_mob = mobs_to_distance_map.keys()[0]
			for m in mobs_to_distance_map:
				if mobs_to_distance_map[m] < mobs_to_distance_map[closest_mob]:
					closest_mob = m
			if mobs_to_distance_map[closest_mob] <= player.weapon.attack_range+1:
				player.emit_signal('perform_game_action', GameAction.Actions.ATTACK, { 'actor': player, 'victim': closest_mob })
#				action_successful = true
			else:
				player.hud.log_container.add_entry('Out of range!')
		else:
			player.hud.log_container.add_entry('No one in sight!')
	elif action == GameAction.Actions.WAIT:
		action_successful = true # I mean, what else is there to do?
	
	if action_successful and data['actor'] == player:
		process_turn({ 'new_position': player.position })
