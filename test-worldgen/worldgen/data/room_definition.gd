extends Resource
class_name RoomDefinition

@export var scene: PackedScene
@export var footprint: Vector3i = Vector3i(1, 1, 1)

@export_group("Rarity Settings")
@export var rarity: G.RARITY
@export var weight: float = 1.0

@export_group("Placement Rules")
@export var min_count: int = 0
@export var max_count: int = -1
@export var min_distance_from_start: int = -1
@export var unique: bool = false

