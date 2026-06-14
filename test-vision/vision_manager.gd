extends Node
## Wires the vision-mask SubViewport texture into every shader that needs it:
##   * the full-screen world post-process (world_vision.gdshader)
##   * every entity material (entity_vision.gdshader), found via group.
##
## The ViewportTexture is a live handle: its CONTENTS update every frame as the
## mask redraws, so we only need to assign the reference once. Call
## register_entity() for anything spawned at runtime.

const ENTITY_GROUP := "vision_entity"
const MASK_PARAM := "vision_mask"

@export var mask_viewport: SubViewport
## The ColorRect carrying world_vision.gdshader.
@export var world_post: ColorRect


func _ready() -> void:
	if mask_viewport == null:
		push_warning("VisionManager: mask_viewport not assigned.")
		return

	# Render the mask continuously.
	mask_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	var tex := mask_viewport.get_texture()

	if world_post and world_post.material is ShaderMaterial:
		(world_post.material as ShaderMaterial).set_shader_parameter(MASK_PARAM, tex)

	for node in get_tree().get_nodes_in_group(ENTITY_GROUP):
		_apply_mask_to(node, tex)


## Hook up an entity created after _ready(). Add it to the "vision_entity" group
## with a material using entity_vision.gdshader, then call this.
func register_entity(node: GeometryInstance3D) -> void:
	if mask_viewport:
		_apply_mask_to(node, mask_viewport.get_texture())


func _apply_mask_to(node: Node, tex: Texture) -> void:
	var geo := node as GeometryInstance3D
	if geo == null:
		return
	var mat = geo.get_active_material(0)
	if mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter(MASK_PARAM, tex)
