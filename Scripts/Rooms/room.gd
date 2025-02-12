class_name Room extends Node2D

@export var room_type: RoomTypes.RoomType = RoomTypes.RoomType.NORMAL
@export var size: Vector2i

func _ready():
    # Calculate size based on TileMap
    if has_node("TileMap"):
        var tilemap = get_node("TileMap")
        var used_rect = tilemap.get_used_rect()
        size = used_rect.size