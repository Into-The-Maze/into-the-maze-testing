extends RefCounted
class_name StatusInstance

var def: StatusDef
var context: StringName
var remaining: float
var stacks: int = 1
var source: Node

func key() -> StringName:
	return def.id if context == &"" else StringName("%s:%s"%[def.id,context])
