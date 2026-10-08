extends RefCounted
class_name Stat

var base: float
var min_value: float
var max_value: float
var value: float

func _init(def: StatDef = null) -> void:
	if def:
		base = def.base
		min_value = def.min_value
		max_value = def.max_value
	value = base

func update(modifiers: Array, conditions: Conditions):
	pass
