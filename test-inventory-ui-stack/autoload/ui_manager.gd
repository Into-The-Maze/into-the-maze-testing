extends Node

const PANELS := {
	&"inventory": preload("res://inventory/ui/inventory_grid.tscn")
}

var drag_rotated: bool = false

func spawn_inventory(inv: Inventory):
	var inv_panel = PANELS[&"inventory"].instantiate()
	add_child(inv_panel)
	inv_panel.inventory = inv
	test(inv_panel.inventory)

func can_move(to_inv: Inventory, id_unique: String, top_left: Vector2i, rotated: bool) -> bool:
	return to_inv.can_place_at(id_unique, top_left, rotated)

func try_move(from_inv: Inventory, to_inv: Inventory, id_unique: String, top_left: Vector2i, rotated: bool) -> bool:
	if not to_inv.can_place_at(id_unique, top_left, rotated):
		return false

	var origin: InventoryEntry = from_inv.take_item(id_unique)
	if origin == null:
		return false

	var result := to_inv.place_item(id_unique, top_left, rotated)
	match result:
		Inventory.PlacementResult.PLACED, Inventory.PlacementResult.MERGE_FULL:
			return true
		_:
			from_inv.place_item(id_unique, origin.top_left, origin.rotated)
			return result == Inventory.PlacementResult.MERGE_PART

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Rotate") and get_viewport().gui_is_dragging():
		drag_rotated = not drag_rotated

func test(inv: Inventory):
	var bandage = ITEM_INSTANCE_REGISTRY.create_instance(&"bandage")
	inv.auto_insert_item(bandage.id_unique)
	var mre = ITEM_INSTANCE_REGISTRY.create_instance(&"mre")
	inv.auto_insert_item(mre.id_unique)
