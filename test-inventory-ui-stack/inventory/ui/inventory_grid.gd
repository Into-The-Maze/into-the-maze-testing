extends NinePatchRect

const CELL_SIZE := 32
const ITEM_CONTAINER := preload("res://inventory/ui/item_container.tscn")
var _drag_preview: ItemContainer = null

var inventory: Inventory = null:
	set(value):
		_unbind()
		inventory = value
		_bind()
		custom_minimum_size = Vector2(inventory.grid_size) * CELL_SIZE
		_rebuild_all_icons()
		queue_redraw()

# String id_unique -> ItemContainer icon
var _icons: Dictionary = {}


func _ready() -> void:
	UI_MANAGER.drag_rotated_changed.connect(_on_drag_rotated_changed)

### Item Handling ###
func _on_item_placed(id_unique: String, top_left: Vector2i, rotated: bool) -> void:
	var entry := InventoryEntry.new()
	entry.top_left = top_left
	entry.rotated = rotated
	_spawn_item_container(id_unique, entry)

func _on_item_removed(id_unique: String) -> void:
	var icon: ItemContainer = _icons.get(id_unique, null)
	if icon == null: return
	icon.queue_free()
	_icons.erase(id_unique)

func _on_item_merged(target_id: String, _new_quantity: int) -> void:
	var icon: ItemContainer = _icons.get(target_id, null)
	if icon == null: return
	icon.update(target_id, inventory.get_placement(target_id).rotated)

func _rebuild_all_icons() -> void:
	_clear_all_icons()
	if inventory == null:
		return
	for id_unique in inventory.get_all_placements():
		_spawn_item_container(id_unique, inventory.get_placement(id_unique))

func _clear_all_icons() -> void:
	for icon in _icons.values():
		icon.queue_free()
	_icons.clear()

func _spawn_item_container(id_unique: String, entry: InventoryEntry) -> void:
	var icon: ItemContainer = _icons.get(id_unique, null)
	if icon == null:
		icon = ITEM_CONTAINER.instantiate()
		_icons[id_unique] = icon
		add_child(icon)
	icon.position = Vector2(entry.top_left) * CELL_SIZE
	icon.update(id_unique, entry.rotated)

### Input ###
func _get_drag_data(at_position: Vector2) -> Variant:
	var cell := Vector2i(at_position / CELL_SIZE)
	var id := inventory.get_item_at(cell)
	if id == "": return null

	UI_MANAGER.drag_rotated = inventory.get_placement(id).rotated

	var preview: ItemContainer = ITEM_CONTAINER.instantiate()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_preview = preview

	var wrapper := Control.new()
	wrapper.add_child(preview)
	set_drag_preview(wrapper)

	_refresh_preview(id, UI_MANAGER.drag_rotated)

	return {"id": id, "from": inventory, "origin": cell}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not (data is Dictionary and data.has("id")): return false
	return UI_MANAGER.can_move(inventory, data.id, _drop_cell(at_position, data.id), UI_MANAGER.drag_rotated)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	UI_MANAGER.try_move(data.from, inventory, data.id, _drop_cell(at_position, data.id), UI_MANAGER.drag_rotated)

func _drop_cell(at_position: Vector2, id_unique: String) -> Vector2i:
	var footprint := inventory.get_footprint(id_unique, UI_MANAGER.drag_rotated)
	return Vector2i((at_position / CELL_SIZE - Vector2(footprint) / 2.0).round())

func _on_drag_rotated_changed(rotated: bool) -> void:
	if not is_instance_valid(_drag_preview): return
	_refresh_preview(_drag_preview.current_id, rotated)

func _refresh_preview(id: String, rotated: bool) -> void:
	_drag_preview.update(id, rotated)
	var target := Vector2(inventory.get_footprint(id, rotated)) * CELL_SIZE
	_drag_preview.custom_minimum_size = target
	_drag_preview.size = target
	_drag_preview.position = -target / 2.0

### Internal ###
func _bind():
	if inventory == null: return
	inventory.item_placed.connect(_on_item_placed)
	inventory.item_removed.connect(_on_item_removed)
	inventory.item_merged.connect(_on_item_merged)

func _unbind():
	if inventory == null: return
	if inventory.item_placed.is_connected(_on_item_placed):
		inventory.item_placed.disconnect(_on_item_placed)
	if inventory.item_removed.is_connected(_on_item_removed):
		inventory.item_removed.disconnect(_on_item_removed)
	if inventory.item_merged.is_connected(_on_item_merged):
		inventory.item_merged.disconnect(_on_item_merged)
