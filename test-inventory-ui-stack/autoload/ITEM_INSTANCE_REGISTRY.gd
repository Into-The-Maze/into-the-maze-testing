extends Node

signal instance_created(instance: ItemInstance)
signal instance_destroyed(instance_id: String)

# String uuid -> ItemInstance
var _instances: Dictionary = {}
var _rng = RandomNumberGenerator.new()

### API ###
func create_instance(def_id: StringName, quantity: int = 1) -> ItemInstance:
	if !ITEM_DEFINITION_REGISTRY.has_definition(def_id):
		#ERROR
		return null

	var instance = ItemInstance.new()
	instance.id_unique = _generate_uuid()
	instance.id_def = def_id
	instance.quantity = quantity
	_instances[instance.id_unique] = instance
	instance_created.emit(instance)

	return instance

func destroy_instance(instance_id: String) -> void:
	if !_instances.has(instance_id):
		#ERROR
		return

	_instances.erase(instance_id)
	instance_destroyed.emit(instance_id)

func get_instance(instance_id: String) -> ItemInstance:
	if !_instances.has(instance_id):
		#ERROR
		return null

	return _instances[instance_id]

func has_instance(instance_id: String) -> bool:
	return _instances.has(instance_id)

func get_all_instances() -> Array[ItemInstance]:
	return _instances.values()

### Internal ###
func _ready() -> void:
	_rng.randomize()

func _generate_uuid() -> String:
	var bytes := PackedByteArray()
	for i in 16:
		bytes.append(_rng.randi_range(0, 255))
	bytes[6] = (bytes[6] & 0x0F) | 0x40
	bytes[8] = (bytes[8] & 0x3F) | 0x80
	var hex := bytes.hex_encode()
	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8),
		hex.substr(8, 4),
		hex.substr(12, 4),
		hex.substr(16, 4),
		hex.substr(20, 12),
	]

