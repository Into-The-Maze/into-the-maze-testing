extends Node

@export var panel_def: Dictionary[StringName, PanelDefinition]
var open_panels: Dictionary[StringName, Node] = {}

signal UI_CONTAINER_SELECTED (key: StringName)

func _ready() -> void:
	UI_CONTAINER_SELECTED.connect(move_to_top)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Rotate") and get_viewport().gui_is_dragging():
		drag_rotated = not drag_rotated

func open_panel(panel_id: StringName, key: StringName = panel_id) -> Control:
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
	if "key" in panel:
		panel.key = key
	return panel

func move_to_top(key: StringName):
	if !key: return
	var panel = open_panels[key]
	move_child(panel, -1)

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

func begin_split(from_inv: Inventory, to_inv: Inventory, id_unique: String, top_left: Vector2i, rotated: bool) -> void:
	var limit = to_inv.get_split_limit(id_unique, top_left, rotated)
	if limit < 1:
		return

	var dialog: UISplitStack = open_panel(&"ui_split_stack")
	dialog.prepare(limit, get_viewport().get_mouse_position())
	dialog.confirmed.connect(_finish_split.bind(from_inv, to_inv, id_unique, top_left, rotated))

func _finish_split(amount: int, from_inv: Inventory, to_inv: Inventory, id_unique: String, top_left: Vector2i, rotated: bool) -> void:
	if from_inv.get_placement(id_unique) == null:
		return
	if amount > to_inv.get_split_limit(id_unique, top_left, rotated):
		return

	var split_id := from_inv.split_stack(id_unique, amount)
	if split_id == "":
		return

	var result := to_inv.place_item(split_id, top_left, rotated)
	match result:
		Inventory.PlacementResult.PLACED, Inventory.PlacementResult.MERGE_FULL:
			return
		_:
			if not from_inv.auto_insert_item(split_id):
				push_warning("Split leftover %s could not be returned to origin" % split_id)

