extends Resource
class_name StatusDef

enum Stacking {
	REFRESH,
	EXTEND,
	STACK,
	IGNORE
}

@export var id: StringName
@export var name: String
@export var icon: Texture2D
@export var tags: Array[StringName] = []
@export var duration: float = -1 # -1 = no timer
@export var stacking: Stacking = Stacking.REFRESH
@export var max_stacks: int = 1
@export var modifiers: Array[ModifierDef] = []
