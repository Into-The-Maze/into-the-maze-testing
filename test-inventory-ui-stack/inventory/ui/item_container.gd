extends PanelContainer
class_name ItemContainer

var texture
var stack

func _ready() -> void:
	texture = $C/ItemTexture
	stack = $Stack

func update(id_unique: String):
	var inst = ITEM_INSTANCE_REGISTRY.get_instance(id_unique)
	var def = ITEM_DEFINITION_REGISTRY.get_definition(inst.id_def)
	set_image(def)
	set_stack(inst, def)

func set_image(def: ItemDefinition):
	texture.texture = def.item_2d

func set_stack(inst: ItemInstance, def: ItemDefinition):
	if def.is_stackable:
		stack.visible = true
		stack.text = "%s/%s"%[inst.quantity,def.max_stack_size]
	else:
		stack.visible = false
		stack.text = ""
