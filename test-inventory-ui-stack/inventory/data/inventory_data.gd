extends Resource
class_name InventoryData

@export var grid_size: Vector2i = Vector2i.ZERO

# Vector2i cell -> String id_unique
var occupied_cells: Dictionary = {}

# String id_unique -> InventoryEntry
var placements: Dictionary = {}

