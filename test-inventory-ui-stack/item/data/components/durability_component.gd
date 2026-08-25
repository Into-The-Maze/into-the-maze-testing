extends ItemComponent
class_name DurabilityComponent

@export var current_durability: float = 0.0

func is_broken() -> bool:
	return current_durability <= 0.0

func apply_wear(amount: float) -> bool:
	var was_broken = is_broken()
	current_durability = maxf(current_durability - amount, 0.0)
	return not was_broken and is_broken()
