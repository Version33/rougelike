@tool
class_name DungeonGraphData extends Resource

@export var graph_nodes: Dictionary = {}
@export var next_node_id: int = 1
@export var room_type_scenes: Dictionary = {}

func _init() -> void:
	for room_type in RoomTypes.RoomType:
		var array: Array[Object] = []
		room_type_scenes[room_type] = array