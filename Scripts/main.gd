# MainScene.gd
extends Node2D

func _ready():
    $DungeonGenerator.generate_dungeon()