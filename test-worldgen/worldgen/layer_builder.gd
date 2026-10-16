# Constructs the maze in-game given a LayerDefinition.
extends Node
class_name LayerBuilder

@export var layer: LayerDef

func _ready() -> void:
	layer.init_maze()
	layer.print_maze()
