extends Node
class_name ItemInstance

@export var id_unique: String = ""
@export var id_def: StringName = &""
@export var quantity: int = 1
@export var components: Dictionary = {} # StringName -> ItemComponent

func get_component(key: StringName) -> ItemComponent:
	return components.get(key)

func has_component(key: StringName) -> bool:
	return components.has(key)

func set_component(key: StringName, component: ItemComponent) -> void:
	components[key] = component

func remove_component(key: StringName) -> void:
	components.erase(key)
