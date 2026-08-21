extends Resource
class_name ItemDefinition

# Abstract class for items.

@export var id: StringName = &""
@export var name: String = ""
@export var description: String = ""

@export var item_2d: Texture2D
@export var item_3d: PackedScene

@export var grid_size: Vector2i = Vector2i(1, 1)
@export var max_stack_size: int = 1
@export var is_stackable: bool = false

