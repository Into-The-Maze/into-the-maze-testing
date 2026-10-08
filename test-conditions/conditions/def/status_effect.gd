@abstract
class_name StatusEffect extends Resource

@abstract
func on_apply(conditions: Conditions, instance: StatusInstance) -> void

@abstract
func on_tick(conditions: Conditions, instance: StatusInstance, delta: float) -> void

@abstract
func on_remove(conditions: Conditions, instance: StatusInstance) -> void
