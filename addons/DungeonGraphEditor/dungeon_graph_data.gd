class_name DungeonGraphData extends Resource

@export var room_type_scenes: Dictionary = {}  # RoomType (int) -> Array[PackedScene]
@export var graph_nodes : Dictionary = {} # String -> {type : int, position : Vector2, connections: Array[String]}
@export var next_node_id = 0

func _init():
	if room_type_scenes == null:
		room_type_scenes = {}

	for k in room_type_scenes: # Remove Old Keys
		if not k in RoomTypes.RoomType.values():
			room_type_scenes.erase(k)
	for room_type in RoomTypes.RoomType: # Create new keys
			if not room_type in room_type_scenes:
				room_type_scenes[room_type] = []