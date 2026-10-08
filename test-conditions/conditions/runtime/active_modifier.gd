extends RefCounted
class_name ActiveModifier

var def: ModifierDef
var source: Object

func _init(init_def: ModifierDef, init_source: Object) -> void:
	def = init_def
	source = init_source

