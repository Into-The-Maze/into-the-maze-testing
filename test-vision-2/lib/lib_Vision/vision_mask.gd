extends Node2D

@export_group("Field of View")
@export_range(1.0, 359.0) var fov_degrees: float = 90.0
@export var vision_radius: float = 18.0
@export var near_radius: float = 3.5
@export_group("Quality")
@export var cone_rays: int = 128
@export var circle_rays: int = 128
@export_flags_3d_physics var occluders_mask: int = 1
@export var occlusion_enabled: bool = true

var _cone_points: PackedVector2Array = PackedVector2Array()
var _circle_points: PackedVector2Array = PackedVector2Array()
var _viewport_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	_match_viewport_size()
	get_window().size_changed.connect(_match_viewport_size)

func _match_viewport_size() -> void:
	var sub := get_parent() as SubViewport
	if sub:
		sub.size = get_window().size

func _physics_process(_delta: float) -> void:
	_viewport_size = Vector2(get_window().size)
	var cam = Vision.instances.camera
	if cam == null or Vision.instances.player == null:
		_cone_points = PackedVector2Array()
		_circle_points = PackedVector2Array()
		queue_redraw()
		return

	var origin := Vision.instances.player.global_position
	var center := cam.unproject_position(origin)

	var fwd := -Vision.instances.player.global_transform.basis.z
	var facing := atan2(fwd.z, fwd.x)
	var half_fov := deg_to_rad(fov_degrees) * 0.5

	_cone_points = _build_fan(cam, origin, center, facing - half_fov, facing + half_fov, cone_rays, vision_radius)
	_circle_points = _build_fan(cam, origin, center, -PI, PI, circle_rays, near_radius)

	queue_redraw()

func _build_fan(cam: Camera3D, origin: Vector3, center: Vector2, start_angle: float, end_angle: float, rays: int, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(center)

	var space := Vision.instances.player.get_world_3d().direct_space_state
	var steps: int = max(rays, 2)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var angle: float = lerp(start_angle, end_angle, t)
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var world_end := origin + dir * radius

		if occlusion_enabled:
			var query := PhysicsRayQueryParameters3D.create(origin, world_end)
			query.collision_mask = occluders_mask
			query.exclude = [Vision.instances.player.get_rid()]
			var hit := space.intersect_ray(query)
			if not hit.is_empty():
				world_end = hit.position

		pts.append(cam.unproject_position(world_end))

	return pts


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _viewport_size), Color.BLACK)
	_draw_fan(_cone_points)
	_draw_fan(_circle_points)

func _draw_fan(pts: PackedVector2Array) -> void:
	var n := pts.size()
	if n < 3:
		return

	var indices := PackedInt32Array()
	for i in range(1, n - 1):
		indices.append(0)
		indices.append(i)
		indices.append(i + 1)

	var colors := PackedColorArray()
	colors.resize(n)
	colors.fill(Color.WHITE)

	RenderingServer.canvas_item_add_triangle_array(
		get_canvas_item(), indices, pts, colors
	)
