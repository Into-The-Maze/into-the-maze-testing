extends Node

@export var panel_def: Dictionary[StringName, PanelDefinition]
var open_panels: Dictionary[StringName, Node] = {}


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Rotate") and get_viewport().gui_is_dragging():
		drag_rotated = not drag_rotated

func open_panel(panel_id: StringName, key: StringName = panel_id) -> Node:
	var def := panel_def[panel_id]

	if open_panels.has(key):
		var existing := open_panels[key]
		match def.behaviour:
			PanelDefinition.Behaviour.TOGGLE:
				existing.queue_free()
				return null
			PanelDefinition.Behaviour.MOVE_TO_FRONT:
				move_child(existing, -1)
				return existing

	var panel: Node = def.scene.instantiate()
	add_child(panel)
	open_panels[key] = panel
	panel.tree_exited.connect(func():
		if open_panels.get(key) == panel:
			open_panels.erase(key)
	)
	print(open_panels)
	return panel

### Inventory ###
signal drag_rotated_changed(rotated: bool)

var drag_rotated := false:
	set(value):
		drag_rotated = value
		drag_rotated_changed.emit(value)

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

func test(inv: Inventory):
	var bandage = ITEM_INSTANCE_REGISTRY.create_instance(&"bandage")
	inv.auto_insert_item(bandage.id_unique)
	var mre = ITEM_INSTANCE_REGISTRY.create_instance(&"mre")
	inv.auto_insert_item(mre.id_unique)
