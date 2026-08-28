extends PanelContainer
class_name ItemContainer

func _ready() -> void:
	$C/Stack.visible = false
	$C/Stack.text = ""

func update(id_unique: String):
	var inst := ITEM_INSTANCE_REGISTRY.get_instance(id_unique)
	var def := ITEM_DEFINITION_REGISTRY.get_definition(inst.id_def)
	update_image(def)
	update_stack(def, inst.quantity)

func update_image(def: ItemDefinition):
	$C/ItemTexture.texture = def.item_2d

func update_stack(def: ItemDefinition, current_stack: int):
	if !def.is_stackable: $C/Stack.visible = false; $C/Stack.text = ""; return
	$C/Stack.visible = true
	$C/Stack.text = "%s/%s" % [str(current_stack), str(def.max_stack_size)]

