extends NinePatchRect

const CELL_SIZE := 32

var inventory: Inventory = null:
	set(value):
		_unbind()
		inventory = value
		_bind()
		custom_minimum_size = Vector2(inventory.grid_size) * CELL_SIZE
		queue_redraw()

# String id_unique -> Control icon
var _icons: Dictionary = {}

### Item Handling ###
func _on_item_placed(id_unique: String, top_left: Vector2i, rotated: bool) -> void:
	pass

func _on_item_removed(id_unique: String) -> void:
	pass

func _on_item_merged(target_id: String, _new_quantity: int) -> void:
	pass

### Input ###
func _gui_input(event: InputEvent) -> void:
	pass

### Internal ###
func _bind():
	pass

func _unbind():
	pass

