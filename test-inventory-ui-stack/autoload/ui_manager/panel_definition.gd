extends Resource
class_name PanelDefinition

enum Behaviour { TOGGLE, MOVE_TO_FRONT }

@export var scene: PackedScene
@export var behaviour: Behaviour

