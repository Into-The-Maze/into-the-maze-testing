extends Resource
class_name MeterDef

@export var id: StringName
@export var name: String
@export var min_value: float = 0.0
@export var base_max_value: float = 100.0
@export var base_rate: float = 0.0
@export var start_value: float = -1 # -1 starts at max
@export var tags: Array[StringName] = []
