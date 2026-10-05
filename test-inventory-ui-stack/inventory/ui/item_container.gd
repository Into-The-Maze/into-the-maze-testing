extends PanelContainer
class_name ItemContainer

var texture: TextureRect
var stack: Label
var current_id: String

func _ready() -> void:
	texture = $ItemTexture
	stack = $Stack

func update(id_unique: String, is_rotated: bool):
	current_id = id_unique
	var inst = ITEM_INSTANCE_REGISTRY.get_instance(id_unique)
	var def = ITEM_DEFINITION_REGISTRY.get_definition(inst.id_def)
	set_image(def, is_rotated)
	set_stack(inst, def)

func set_image(def: ItemDefinition, is_rotated: bool):
	if def.item_2d == null:
		texture.texture = null
		return
	if not is_rotated:
		texture.texture = def.item_2d
		return
	var img: Image = def.item_2d.get_image()
	img.rotate_90(CLOCKWISE)
	texture.texture = ImageTexture.create_from_image(img)

func set_stack(inst: ItemInstance, def: ItemDefinition):
	if def.is_stackable:
		stack.visible = true
		stack.text = "%s/%s"%[inst.quantity,def.max_stack_size]
	else:
		stack.visible = false
		stack.text = ""
