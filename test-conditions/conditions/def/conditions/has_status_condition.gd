extends Condition
class_name HasStatusCondition

@export var status_id: StringName
@export var tag: StringName

func evaluate(conditions: Conditions) -> bool:
	if status_id != &"":
		return conditions.has_status(status_id)
	return conditions.has_status_tag(tag)
