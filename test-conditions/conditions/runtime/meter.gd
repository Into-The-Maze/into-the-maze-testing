extends RefCounted
class_name Meter

var def: MeterDef
var current: float

func _init(init_def: MeterDef) -> void:
	def = init_def
	current = init_def.base_max_value if init_def.start_value < 0.0 else init_def.start_value
