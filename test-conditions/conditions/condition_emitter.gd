extends Area3D
class_name ConditionEmitter

@export var modifiers: Array[ModifierDef] = []

func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)

func _on_enter(body: Node3D) -> void:
	var conditions := Conditions.of(body)
	if conditions:
		for mod in modifiers:
			conditions.add_modifier(mod, self)

func _on_exit(body: Node3D) -> void:
	var conditions := Conditions.of(body)
	if conditions:
		conditions.remove_modifiers_from_source(self)
