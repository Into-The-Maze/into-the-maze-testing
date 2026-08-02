extends Node

@export var mask: SubViewport
@export var world: ColorRect

func _ready() -> void:
	var texture = mask.get_texture()
	world.material.set_shader_parameter(Vision.SHADER_ARG_MASK, texture)

func register_entity(node: Node) -> void:
	var texture = mask.get_texture()
	if node is GeometryInstance3D:
		_apply_mask_to(node, texture)
	else:
		for child in node.find_children("*", "GeometryInstance3D", true, false):
			_apply_mask_to(child, texture)

func _apply_mask_to(node: Node, tex: Texture) -> void:
	var geo := node as GeometryInstance3D
	var mat = geo.get_active_material(0)
	if mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter(Vision.SHADER_ARG_MASK, tex)
