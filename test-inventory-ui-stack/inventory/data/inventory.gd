extends Node
class_name Inventory

signal item_placed (id_unique: String, top_left: Vector2i, rotated: bool)
signal item_removed (id_unique: String)
signal item_merged (target_id: String, new_quantity: int)
signal stack_changed(id_unique: String)

enum PlacementResult { PLACED, MERGE_FULL, MERGE_PART, BLOCKED }
enum _Drop { FREE, MERGE, BLOCKED }

const NO_POSITION := Vector2i(-1, -1)

@export var _data := InventoryData.new()

var grid_size: Vector2i:
	get:
		return _data.grid_size

### Queries ###
func get_item_at(cell: Vector2i) -> String:
	return _data.occupied_cells.get(cell, "")

func get_placement(id_unique: String) -> InventoryEntry:
	return _data.placements.get(id_unique, null)

func get_all_placements() -> Dictionary:
	return _data.placements.duplicate()

func can_place_at(id_unique: String, top_left: Vector2i, rotated: bool = false) -> bool:
	return _classify_drop(id_unique, top_left, rotated).kind != _Drop.BLOCKED

func find_free_position(id_unique: String, rotated: bool = false) -> Vector2i:
	var footprint = get_footprint(id_unique, rotated)

	if footprint == Vector2i.ZERO:
		return NO_POSITION

	for y in range(0, grid_size.y - footprint.y + 1):
		for x in range(0, grid_size.x - footprint.x + 1):
			var pos := Vector2i(x, y)
			if _all_cells_free(pos, footprint, id_unique):
				return pos

	return NO_POSITION

### Edit ###
func place_item(id_unique: String, top_left: Vector2i, rotated: bool = false) -> PlacementResult:
	if not ITEM_INSTANCE_REGISTRY.has_instance(id_unique):
		return PlacementResult.BLOCKED

	var drop := _classify_drop(id_unique, top_left, rotated)
	match drop.kind:
		_Drop.FREE:
			_write_placement(id_unique, top_left, rotated)
			return PlacementResult.PLACED
		_Drop.MERGE:
			return _merge_into(id_unique, drop.target)
		_:
			return PlacementResult.BLOCKED

func take_item(id_unique: String) -> InventoryEntry:
	var entry: InventoryEntry = _data.placements.get(id_unique, null)
	if entry == null:
		return null
	_clear_cells(id_unique, entry.top_left, entry.rotated)
	_data.placements.erase(id_unique)
	item_removed.emit(id_unique)
	return entry

func auto_insert_item(id_unique: String, rotated: bool = false) -> bool:
	if not ITEM_INSTANCE_REGISTRY.has_instance(id_unique):
		return false
	var instance: ItemInstance = ITEM_INSTANCE_REGISTRY.get_instance(id_unique)
	var definition: ItemDefinition = ITEM_DEFINITION_REGISTRY.get_definition(instance.id_def)
	if definition == null:
		return false

	if definition.is_stackable:
		for existing_id in _data.placements.keys():
			if instance.quantity <= 0:
				break
			if existing_id == id_unique or not _can_merge(id_unique, existing_id):
				continue
			var target: ItemInstance = ITEM_INSTANCE_REGISTRY.get_instance(existing_id)
			var moved: int = min(definition.max_stack_size - target.quantity, instance.quantity)
			target.quantity += moved
			instance.quantity -= moved
			item_merged.emit(existing_id, target.quantity)
		if instance.quantity <= 0:
			ITEM_INSTANCE_REGISTRY.destroy_instance(id_unique)
			return true

	var pos := find_free_position(id_unique, rotated)
	if pos == NO_POSITION:
		return false
	_write_placement(id_unique, pos, rotated)
	return true

func split_stack(id_unique: String, quantity: int) -> String:
	var item: ItemInstance = ITEM_INSTANCE_REGISTRY.get_instance(id_unique)
	if item == null or quantity < 1 or quantity >= item.quantity:
		return ""
	item.quantity -= quantity
	var split: ItemInstance = ITEM_INSTANCE_REGISTRY.create_instance(item.id_def, quantity)
	stack_changed.emit(id_unique)
	return split.id_unique

func get_split_limit(source_id: String, top_left: Vector2i, rotated: bool = false) -> int:
	var source: ItemInstance = ITEM_INSTANCE_REGISTRY.get_instance(source_id)
	if source == null:
		return 0
	var limit: int = source.quantity - 1
	var drop := _classify_drop(source_id, top_left, rotated, false)
	match drop.kind:
		_Drop.FREE:
			return limit
		_Drop.MERGE:
			var target: ItemInstance = ITEM_INSTANCE_REGISTRY.get_instance(drop.target)
			var definition: ItemDefinition = ITEM_DEFINITION_REGISTRY.get_definition(source.id_def)
			return mini(limit, definition.max_stack_size - target.quantity)
		_:
			return 0

### Internal ###
func _classify_drop(id_unique: String, top_left: Vector2i, rotated: bool, ignore_source: bool = true) -> Dictionary:
	var blocked := { "kind": _Drop.BLOCKED, "target": "" }
	var footprint := get_footprint(id_unique, rotated)

	if footprint == Vector2i.ZERO:
		return blocked
	if top_left.x < 0 or top_left.y < 0:
		return blocked
	if top_left.x + footprint.x > grid_size.x or top_left.y + footprint.y > grid_size.y:
		return blocked

	var occupant := ""
	var occupied_count := 0

	for x in range(top_left.x, top_left.x + footprint.x):
		for y in range(top_left.y, top_left.y + footprint.y):
			var here: String = _data.occupied_cells.get(Vector2i(x, y), "")
			if here == "" or (ignore_source and here == id_unique):
				continue
			occupied_count += 1
			if occupant == "":
				occupant = here
			elif occupant != here:
				return blocked

	if occupied_count == 0:
		return { "kind": _Drop.FREE, "target": "" }
	if occupied_count == footprint.x * footprint.y and occupant != id_unique and _can_merge(id_unique, occupant):
		return { "kind": _Drop.MERGE, "target": occupant }

	return blocked

func _can_merge(source_id: String, target_id: String) -> bool:
	var source: ItemInstance = ITEM_INSTANCE_REGISTRY.get_instance(source_id)
	var target: ItemInstance = ITEM_INSTANCE_REGISTRY.get_instance(target_id)
	if source == null or target == null:
		return false
	if source.id_def != target.id_def:
		return false
	var definition: ItemDefinition = ITEM_DEFINITION_REGISTRY.get_definition(source.id_def)
	if definition == null or not definition.is_stackable:
		return false
	return target.quantity < definition.max_stack_size

func _merge_into(source_id: String, target_id: String) -> PlacementResult:
	var source: ItemInstance = ITEM_INSTANCE_REGISTRY.get_instance(source_id)
	var target: ItemInstance = ITEM_INSTANCE_REGISTRY.get_instance(target_id)
	var definition: ItemDefinition = ITEM_DEFINITION_REGISTRY.get_definition(source.id_def)
	var moved: int = min(definition.max_stack_size - target.quantity, source.quantity)

	if moved <= 0:
		return PlacementResult.BLOCKED

	target.quantity += moved
	source.quantity -= moved
	item_merged.emit(target_id, target.quantity)

	if source.quantity <= 0:
		ITEM_INSTANCE_REGISTRY.destroy_instance(source_id)
		return PlacementResult.MERGE_FULL
	return PlacementResult.MERGE_PART

func _write_placement(id_unique: String, top_left: Vector2i, rotated: bool) -> void:
	if _data.placements.has(id_unique):
		var old: InventoryEntry = _data.placements[id_unique]
		_clear_cells(id_unique, old.top_left, old.rotated)

	_stamp_cells(id_unique, top_left, rotated)
	var entry := InventoryEntry.new()
	entry.top_left = top_left
	entry.rotated = rotated
	_data.placements[id_unique] = entry
	item_placed.emit(id_unique, top_left, rotated)

func _stamp_cells(id_unique: String, top_left: Vector2i, rotated: bool) -> void:
	var footprint := get_footprint(id_unique, rotated)
	for x in range(top_left.x, top_left.x + footprint.x):
		for y in range(top_left.y, top_left.y + footprint.y):
			_data.occupied_cells[Vector2i(x, y)] = id_unique

func _clear_cells(id_unique: String, top_left: Vector2i, rotated: bool) -> void:
	var footprint := get_footprint(id_unique, rotated)
	for x in range(top_left.x, top_left.x + footprint.x):
		for y in range(top_left.y, top_left.y + footprint.y):
			_data.occupied_cells.erase(Vector2i(x, y))

func _all_cells_free(top_left: Vector2i, footprint: Vector2i, ignore_id: String = "") -> bool:
	for x in range(top_left.x, top_left.x + footprint.x):
		for y in range(top_left.y, top_left.y + footprint.y):
			var here: String = _data.occupied_cells.get(Vector2i(x, y), "")
			if here != "" and here != ignore_id:
				return false
	return true

func get_footprint(id_unique: String, rotated: bool) -> Vector2i:
	if not ITEM_INSTANCE_REGISTRY.has_instance(id_unique):
		return Vector2i.ZERO
	var instance: ItemInstance = ITEM_INSTANCE_REGISTRY.get_instance(id_unique)
	var definition: ItemDefinition = ITEM_DEFINITION_REGISTRY.get_definition(instance.id_def)
	if definition == null:
		return Vector2i.ZERO
	if rotated:
		return Vector2i(definition.grid_size.y, definition.grid_size.x)
	return definition.grid_size
