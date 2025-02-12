# DungeonGenerator.gd
class_name DungeonGenerator
extends Node2D

@export var dungeon_graph_data: DungeonGraphData  # Use the new resource type
@export var grid_cell_size: Vector2 = Vector2(32, 32)
@export var max_corridor_length: int = 5

var placed_rooms: Dictionary = {}

# --- Constants ---
const INVALID_POSITION = Vector2i(-9999, -9999)
const DOOR_PREFIX = "Door_"
const DOOR_TILE_PREFIX = "DoorTile_"
# -----------------

func generate_dungeon():
	placed_rooms.clear()

	if not dungeon_graph_data:
		push_error("No DungeonGraphData assigned!")
		return

	# Find the start node.
	var start_node_id = null
	for node_id in dungeon_graph_data.graph_nodes:
		if dungeon_graph_data.graph_nodes[node_id].type == RoomTypes.RoomType.ENTRANCE:
			start_node_id = node_id
			break
	if start_node_id == null:
		push_error("No Entrance node found in graph!")
		return

	# Instantiate and place the start room.
	var start_room_scene = select_room_scene(RoomTypes.RoomType.ENTRANCE)
	var start_room = start_room_scene.instantiate()
	add_child(start_room)
	start_room.position = Vector2(0, 0) * grid_cell_size
	placed_rooms[start_node_id] = { "room": start_room, "rect": Rect2i(Vector2i(0, 0), start_room.size) }

	place_connected_rooms(start_node_id)

func place_connected_rooms(current_node_id: String):
	if not dungeon_graph_data.graph_nodes.has(current_node_id):
		push_error("Invalid node ID: ", current_node_id)
		return

	var current_node_data = dungeon_graph_data.graph_nodes[current_node_id]
	var current_room = placed_rooms[current_node_id].room

	for connected_node_id in current_node_data.connections:
		if not placed_rooms.has(connected_node_id): # Check if placed by ID
			var connected_node_data = dungeon_graph_data.graph_nodes[connected_node_id]
			var next_room_scene = select_room_scene(connected_node_data.type)
			var next_room = next_room_scene.instantiate()

			var placement_data = find_placement_position(current_room, next_room)
			if placement_data:
				var corridor_positions = placement_data[0]
				var next_room_position = placement_data[1]

				for pos in corridor_positions:
					place_corridor(pos)

				add_child(next_room)
				next_room.position = Vector2(next_room_position) * grid_cell_size

				# Store using the node ID as the key
				placed_rooms[connected_node_id] = { "room": next_room, "rect": Rect2i(next_room_position, next_room.size) }
				place_connected_rooms(connected_node_id)  # Pass ID, not room instance



func select_room_scene(room_type: int) -> PackedScene:
	var possible_scenes = dungeon_graph_data.room_type_scenes[room_type]
	if possible_scenes.size() > 0:
		return possible_scenes[randi_range(0, possible_scenes.size() - 1)]
	else:
		push_error("No scenes found for room type: ", room_type)
		return null

func place_corridor(grid_position: Vector2i):
	var corridor_scene = select_room_scene(RoomTypes.RoomType.CORRIDOR)
	var corridor = corridor_scene.instantiate()
	add_child(corridor)
	corridor.position = Vector2(grid_position) * grid_cell_size
	# Use a consistent key for corridor placement.  We'll just use its position.
	var corridor_id = "corridor_" + str(grid_position)
	placed_rooms[corridor_id] = {"room": corridor, "rect": Rect2i(grid_position, corridor.size)}

func find_placement_position(current_room, next_room) -> Array:
	var current_room_rect = get_room_rect(current_room)
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for dir in directions:
		var corridor_positions : Array[Vector2i] = []
		var next_room_size = next_room.size

		var current_room_exit = get_room_exit_point(current_room, dir)
		if current_room_exit == INVALID_POSITION:
			continue

		var next_room_entry = get_room_entry_point(next_room, -dir)
		if next_room_entry == INVALID_POSITION:
			continue

		var start_pos = current_room_rect.position + current_room_exit
		var end_pos = start_pos + (dir * 2)

		var horizontal_first = randi_range(0, 1) == 0

		var path_found = find_corridor_path(start_pos, end_pos, horizontal_first, next_room_size, corridor_positions)
		if path_found:
			var next_room_position = corridor_positions[-1] + (-next_room_entry)
			var next_rect = Rect2i(next_room_position, next_room_size)
			if !check_for_overlaps(next_rect):
				return [corridor_positions, next_room_position]
	return []

func get_room_exit_point(room, dir : Vector2i) -> Vector2i:
	var doors = get_doorway_positions(room)
	var dir_str = ""
	if dir == Vector2i.UP:
		dir_str = "North"
	elif dir == Vector2i.DOWN:
		dir_str = "South"
	elif dir == Vector2i.LEFT:
		dir_str = "West"
	elif dir == Vector2i.RIGHT:
		dir_str = "East"
	if dir_str == "":
		return INVALID_POSITION

	var closest_door_pos = INVALID_POSITION
	var min_dist = 999999
	for door_pos in doors:
		if room.get_node(DOOR_PREFIX+dir_str).has_node(DOOR_TILE_PREFIX+"0"):
			if room.get_node(DOOR_PREFIX+dir_str/(DOOR_TILE_PREFIX+"0")).global_position.distance_squared_to(Vector2(room.size/2)) < min_dist:
				closest_door_pos = Vector2((room.get_node(DOOR_PREFIX+dir_str/(DOOR_TILE_PREFIX+"0")).global_position/grid_cell_size).floor())
				min_dist = room.get_node(DOOR_PREFIX+dir_str/(DOOR_TILE_PREFIX+"0")).global_position.distance_squared_to(Vector2(room.size/2))
		else:
			if room.get_node(DOOR_PREFIX+dir_str).global_position.distance_squared_to(Vector2(room.size/2)) < min_dist:
				closest_door_pos = Vector2((room.get_node(DOOR_PREFIX+dir_str).global_position/grid_cell_size).floor())
				min_dist = room.get_node(DOOR_PREFIX+dir_str).global_position.distance_squared_to(Vector2(room.size/2))
	return closest_door_pos

func get_room_entry_point(room, dir : Vector2i) -> Vector2i:
	var doors = get_doorway_positions(room)
	var dir_str = ""
	if dir == Vector2i.UP:
		dir_str = "North"
	elif dir == Vector2i.DOWN:
		dir_str = "South"
	elif dir == Vector2i.LEFT:
		dir_str = "West"
	elif dir == Vector2i.RIGHT:
		dir_str = "East"
	if dir_str == "":
		return INVALID_POSITION

	var closest_door_pos = INVALID_POSITION
	var min_dist = 999999
	for door_pos in doors:
		if room.get_node(DOOR_PREFIX+dir_str).has_node(DOOR_TILE_PREFIX+"0"):
			if room.get_node(DOOR_PREFIX+dir_str/(DOOR_TILE_PREFIX+"0")).global_position.distance_squared_to(Vector2(room.size/2)) < min_dist:
				closest_door_pos = Vector2((room.get_node(DOOR_PREFIX+dir_str/(DOOR_TILE_PREFIX+"0")).global_position/grid_cell_size).floor())
				min_dist = room.get_node(DOOR_PREFIX+dir_str/(DOOR_TILE_PREFIX+"0")).global_position.distance_squared_to(Vector2(room.size/2))
		else:
			if room.get_node(DOOR_PREFIX+dir_str).global_position.distance_squared_to(Vector2(room.size/2)) < min_dist:
				closest_door_pos = Vector2((room.get_node(DOOR_PREFIX+dir_str).global_position/grid_cell_size).floor())
				min_dist = room.get_node(DOOR_PREFIX+dir_str).global_position.distance_squared_to(Vector2(room.size/2))
	return closest_door_pos

func find_corridor_path(start_pos: Vector2i, end_pos: Vector2i, horizontal_first: bool, next_room_size: Vector2i, corridor_positions: Array[Vector2i]) -> bool:
	corridor_positions.clear()
	var current_pos = start_pos
	corridor_positions.append(current_pos)

	var attempts = 0
	while current_pos != end_pos:
		attempts += 1
		if attempts > max_corridor_length * 4:
			return false

		var next_pos : Vector2i
		if horizontal_first:
			if current_pos.x != end_pos.x:
				next_pos = current_pos + Vector2i(sign(end_pos.x - current_pos.x), 0)
			else:
				next_pos = current_pos + Vector2i(0, sign(end_pos.y - current_pos.y))
		else:
			if current_pos.y != end_pos.y:
				next_pos = current_pos + Vector2i(0, sign(end_pos.y - current_pos.y))
			else:
				next_pos = current_pos + Vector2i(sign(end_pos.x - current_pos.x), 0)

		# Improved Overlap Check
		var overlap = false
		for placed_data in placed_rooms.values():
			var placed_rect = placed_data.rect
			if Rect2i(next_pos, Vector2i(1,1)).intersects(placed_rect):
				overlap = true
				break
		if overlap:
			return false

		corridor_positions.append(next_pos)
		current_pos = next_pos

	# Final Check
	var next_room_rect = Rect2i(end_pos, next_room_size)
	if check_for_overlaps(next_room_rect):
		return false

	return true
	
func check_for_overlaps(rect: Rect2i) -> bool:
	for placed_data in placed_rooms.values():
		if rect.intersects(placed_data.rect):
			return true
	return false

func get_doorway_positions(room) -> Array[Vector2i]:
	var doorways: Array[Vector2i] = []
	for child in room.get_children():
		if child is Node2D and child.name.begins_with(DOOR_PREFIX):
			if child.get_child_count() > 0:
				for door_tile in child.get_children():
					if door_tile is Node2D:
						var grid_pos = (door_tile.global_position / grid_cell_size).floor()
						doorways.append(grid_pos)
			else:
				var grid_pos = (child.global_position / grid_cell_size).floor()
				doorways.append(grid_pos)
	return doorways

func get_room_rect(room) -> Rect2i:
	for data in placed_rooms.values():
		if data.room == room:
			return data.rect
	# If not found, return a default Rect2i (and push an error)
	push_error("Room not found in placed_rooms: ", room)
	return Rect2i()  # Return an empty Rect2i