extends Node3D

func _ready() -> void:
	var loot = ITEM_INSTANCE_REGISTRY.create_instance(&"bandage")
	$Inventory.auto_insert_item(loot.id_unique)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Loot"):
		var panel = UI_MANAGER.open_panel(&"inventory", &"chest")
		panel.content.inventory = $Inventory
