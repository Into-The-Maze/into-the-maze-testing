extends NinePatchRect

const CELL_SIZE := 32
const ITEM_CONTAINER := preload("res://inventory/ui/item_container.tscn")

var inventory: Inventory = null:
	set(value):
		_unbind()
		inventory = value
		_bind()
		custom_minimum_size = Vector2(inventory.grid_size) * CELL_SIZE
		queue_redraw()

# String id_unique -> ItemContainer icon
var _icons: Dictionary = {}

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
	icon.update(target_id)

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
	icon.update(id_unique)

### Input ###
func _gui_input(event: InputEvent) -> void:
	if inventory == null: return
	if event.is_action_pressed("Left Click"):
		var cell := Vector2i(get_local_mouse_position() / CELL_SIZE)
		if !UI_MANAGER.held_item_id == "":
			var target_id := inventory.get_item_at(cell)
			if target_id != "":
				UI_MANAGER.try_take(inventory, target_id)

		else:
			UI_MANAGER.try_place(inventory, cell)


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

