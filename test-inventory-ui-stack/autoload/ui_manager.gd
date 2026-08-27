extends Node

var held_item_id: String = ""
var held_item_is_rotated: bool = false
var held_item_origin_inventory: Inventory = null
var held_item_origin_position: Vector2i = Vector2i.ZERO

func spawn_inventory(inv: Inventory) -> Control:
	return Control.new()

func try_take(inv: Inventory, id_unique: String):
	pass

func try_place(inv: Inventory, top_left: Vector2i, rotated: bool):
	pass


