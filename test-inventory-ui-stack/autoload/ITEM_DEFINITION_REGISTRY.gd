extends Node

const DEFINITION_PATH = "res://resource/item_definition/"

# StringName -> ItemDefinition
var _definitions: Dictionary = {}

### API ###
func get_definition(id: StringName) -> ItemDefinition:
	if !_definitions.has(id):
		#ERROR
		return null
	return _definitions[id]

func has_definition(id: StringName) -> bool:
	return _definitions.has(id)

func get_all_ids() -> Array[StringName]:
	return _definitions.keys()

### Internal ###
func _ready() -> void:
	_load_all_definitions(DEFINITION_PATH)

func _load_all_definitions(path: String) -> void:
	var dir = DirAccess.open(path)
	if !dir:
		#ERROR
		return

	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		var full_path = path.path_join(filename)
		if dir.current_is_dir(): _load_all_definitions(full_path) #recurse
		elif filename.ends_with(".tres") or filename.ends_with(".res"): _load_definition(full_path)
		filename = dir.get_next()
	dir.list_dir_end()

func _load_definition(path: String) -> void:
	var res: Resource = ResourceLoader.load(path)
	if !res or res is not ItemDefinition:
		#ERROR
		return

	var def: ItemDefinition = res
	if def.id == &"":
		#ERROR
		return
	if _definitions.has(def.id):
		#ERROR
		return

	_definitions[def.id] = def
