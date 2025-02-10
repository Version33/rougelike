extends Camera2D

@export var smoothing_speed: float = 5.0
@onready var player: CharacterBody2D = get_tree().get_nodes_in_group("player")[0]
@onready var tile_map_layer: TileMapLayer = get_tree().get_nodes_in_group("room")[0]

var debug_draw_enabled: bool = false
@export var desired_rect_color: Color = Color(1, 0, 0, 0.5)
@export var level_rect_color: Color = Color(0, 1, 0, 0.5)

@export var level_padding: float = 48.0 # Uniform padding around the level rect (pixels)


func _ready() -> void:
	if not tile_map_layer:
		printerr("Error: TileMapLayer node not found! Please set the correct path in the Inspector.")


func _physics_process(delta: float) -> void:
	if not player or not tile_map_layer:
		return

	var target_position: Vector2 = player.global_position

	# 1. Get Level Boundaries from TileMapLayer (with padding)
	var level_rect: Rect2 = get_level_rect()
	if !level_rect.has_area():
		global_position = global_position.lerp(target_position, smoothing_speed * delta)
		if debug_draw_enabled:
			queue_redraw()
		return

	# 2. Calculate Desired Camera Viewport Rectangle
	var viewport_size: Vector2 = get_viewport_rect().size / zoom
	var desired_camera_rect: Rect2 = Rect2(
		target_position - viewport_size / 2.0,
		viewport_size
	)

	# 3. Clamp Camera Position to Level Boundaries
	var clamped_camera_pos: Vector2 = get_clamped_camera_position(desired_camera_rect, level_rect)

	# 4. Smoothly Move Camera
	global_position = global_position.lerp(clamped_camera_pos, smoothing_speed * delta)

	if debug_draw_enabled:
		queue_redraw()


func get_level_rect() -> Rect2:
	var used_cells = tile_map_layer.get_used_cells()
	if used_cells.is_empty():
		return Rect2()

	var min_x: float = INF
	var min_y: float = INF
	var max_x: float = -INF
	var max_y: float = -INF

	var tile_size: Vector2 = tile_map_layer.tile_set.tile_size
	var tile_map_scale: Vector2 = tile_map_layer.scale

	for cell in used_cells:
		var cell_pos: Vector2 = tile_map_layer.map_to_local(cell)
		cell_pos *= tile_map_scale
		var scaled_tile_size: Vector2 = tile_size * tile_map_scale

		min_x = min(min_x, cell_pos.x)
		min_y = min(min_y, cell_pos.y)
		max_x = max(max_x, cell_pos.x + scaled_tile_size.x)
		max_y = max(max_y, cell_pos.y + scaled_tile_size.y)

	var calculated_rect = Rect2(Vector2(min_x, min_y), Vector2(max_x - min_x, max_y - min_y))

	# Apply padding
	var padded_rect = Rect2(
		calculated_rect.position - Vector2(level_padding, level_padding), # Subtract padding from top-left
		calculated_rect.size + Vector2(level_padding * 2.0, level_padding * 2.0) # Add padding to size (twice for each side)
	)

	return padded_rect # Return the padded rectangle


func get_clamped_camera_position(desired_rect: Rect2, level_rect: Rect2) -> Vector2:
	var clamped_pos: Vector2 = desired_rect.get_center()

	# Clamp X
	if desired_rect.position.x < level_rect.position.x:
		clamped_pos.x = level_rect.position.x + desired_rect.size.x / 2.0
	elif desired_rect.end.x > level_rect.end.x:
		clamped_pos.x = level_rect.end.x - desired_rect.size.x / 2.0

	# Clamp Y
	if desired_rect.position.y < level_rect.position.y:
		clamped_pos.y = level_rect.position.y + desired_rect.size.y / 2.0
	elif desired_rect.end.y > level_rect.end.y:
		clamped_pos.y = level_rect.end.y - desired_rect.size.y / 2.0

	return clamped_pos


func _draw() -> void:
	if debug_draw_enabled:
		var level_rect: Rect2 = get_level_rect()
		var viewport_size: Vector2 = get_viewport_rect().size / zoom
		var desired_camera_rect: Rect2 = Rect2(
			player.global_position - viewport_size / 2.0,
			viewport_size
		)

		if level_rect.has_area():
			# Transform level_rect position to camera-local space
			var local_level_rect_pos: Vector2 = to_local(level_rect.position)
			var local_level_rect: Rect2 = Rect2(local_level_rect_pos, level_rect.size)
			draw_rect(local_level_rect, level_rect_color, false)

		# Transform desired_camera_rect position to camera-local space
		var local_desired_rect_pos: Vector2 = to_local(desired_camera_rect.position)
		var local_desired_camera_rect: Rect2 = Rect2(local_desired_rect_pos, desired_camera_rect.size)
		draw_rect(local_desired_camera_rect, desired_rect_color, false)