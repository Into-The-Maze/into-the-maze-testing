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

func recalculate(modifiers: Array, conditions: Conditions) -> bool:
	var flat_add := 0.0
	var percent_add := 0.0
	var mult := 1.0
	for mod: ActiveModifier in modifiers:
		var mod_def := mod.def
		if mod_def.condition and !mod_def.condition.evaluate(conditions): continue
		var amount := mod_def.amount(conditions)
		match mod_def.operation:
			ModifierDef.Operation.FLAT_ADD: flat_add += amount
			ModifierDef.Operation.PERCENT_ADD: percent_add += amount
			ModifierDef.Operation.MULT: mult *= amount

	var new_value := clampf((base + flat_add) * (1.0 + percent_add) * mult, min_value, max_value)
	var changed := !is_equal_approx(value, new_value)
	value = new_value
	return changed
