extends Condition
class_name CompareCondition

enum Compare { LT, LE, GE, GT }

@export var key: StringName
@export var comparison: Compare = Compare.GT
@export var threshold: float = 0.0

func evaluate(conditions: Conditions) -> bool:
	var value := conditions.get_value(key)
	match comparison:
		Compare.LT: return value < threshold
		Compare.LE: return value <= threshold
		Compare.GE: return value >= threshold
		Compare.GT: return value > threshold
		_: return value > threshold
