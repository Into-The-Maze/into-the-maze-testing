extends Resource
class_name ModifierDef

enum Operation {
	FLAT_ADD,
	PERCENT_ADD,
	MULT
}

@export var key: StringName
@export var operation: Operation = Operation.FLAT_ADD
@export var value: float = 0.0
@export var condition: Condition
@export_group("Scale by another value")
@export var scale_key: StringName
@export var scale_curve: Curve

func amount(conditions: Conditions) -> float:
	if scale_curve and scale_key != &"":
		return value * scale_curve.sample(conditions.get_value(scale_key))
	return value
