extends Node2D
## Draws the player's "vision polygon" into a SubViewport, producing a mask
## texture (white = visible, black = hidden) that shaders sample to decide what
## is drawn in full colour, greyscaled, or hidden entirely.
##
## The mask is built in SCREEN space. Because the camera looks straight down,
## a 3D world point projects cleanly to a 2D pixel via Camera3D.unproject_position,
## so this SubViewport (kept the same size as the main window) lines up 1:1 with
## what hint_screen_texture sees in the post-process shader.
##
## Two shapes are drawn, both occluded by walls so you cannot see through them:
##   * a narrow FOV slice in the direction the player faces  (long range)
##   * a small full circle around the player                 (short range)

@export var player: CharacterBody3D
## Optional explicit camera. If null, the main viewport's 3D camera is used.
@export var camera: Camera3D

@export_group("Field of View")
## Total width of the vision cone, in degrees.
@export_range(1.0, 359.0) var fov_degrees: float = 90.0
## How far the player can see straight ahead, in world units.
@export var vision_radius: float = 18.0
## Radius of the always-visible circle directly around the player.
@export var near_radius: float = 3.5

@export_group("Quality")
## Rays cast across the cone arc. More = smoother edges / tighter occlusion.
@export var cone_rays: int = 128
## Rays cast around the near circle.
@export var circle_rays: int = 128
## Physics layers that block vision (walls). Entities should not be on these.
@export_flags_3d_physics var occluders_mask: int = 1
## When false, walls are ignored and the cone/circle are never cut.
@export var occlusion_enabled: bool = true

# Screen-space points computed in _physics_process and consumed in _draw.
var _cone_points: PackedVector2Array = PackedVector2Array()
var _circle_points: PackedVector2Array = PackedVector2Array()
var _viewport_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Make sure the mask viewport matches the window so screen UVs line up.
	_match_viewport_size()
	get_window().size_changed.connect(_match_viewport_size)


func _match_viewport_size() -> void:
	var sub := get_parent() as SubViewport
	if sub:
		sub.size = get_window().size


func _physics_process(_delta: float) -> void:
	# Raycasts must run on the physics thread, so build the geometry here and
	# only draw the cached result in _draw.
	_viewport_size = Vector2(get_window().size)

	var cam := _get_camera()
	if cam == null or player == null:
		_cone_points = PackedVector2Array()
		_circle_points = PackedVector2Array()
		queue_redraw()
		return

	var origin := player.global_position
	var center := cam.unproject_position(origin)

	# Player forward: look_at() aims -Z at the mouse target, so -Z is "facing".
	var fwd := -player.global_transform.basis.z
	var facing := atan2(fwd.z, fwd.x)
	var half_fov := deg_to_rad(fov_degrees) * 0.5

	_cone_points = _build_fan(cam, origin, center, facing - half_fov, facing + half_fov, cone_rays, vision_radius)
	_circle_points = _build_fan(cam, origin, center, -PI, PI, circle_rays, near_radius)

	queue_redraw()


## Casts a fan of rays between two angles and returns a screen-space polygon
## (centre first, then the occluded rim) ready for draw_colored_polygon.
func _build_fan(cam: Camera3D, origin: Vector3, center: Vector2, start_angle: float, end_angle: float, rays: int, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(center)

	var space := player.get_world_3d().direct_space_state
	var steps: int = max(rays, 2)
	for i in steps + 1:
		var t := float(i) / float(steps)
		var angle: float = lerp(start_angle, end_angle, t)
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var world_end := origin + dir * radius

		if occlusion_enabled:
			var query := PhysicsRayQueryParameters3D.create(origin, world_end)
			query.collision_mask = occluders_mask
			query.exclude = [player.get_rid()]
			var hit := space.intersect_ray(query)
			if not hit.is_empty():
				world_end = hit.position

		pts.append(cam.unproject_position(world_end))

	return pts


func _draw() -> void:
	# Black background = "not visible". White polygons = "visible".
	draw_rect(Rect2(Vector2.ZERO, _viewport_size), Color.BLACK)

	_draw_fan(_cone_points)
	_draw_fan(_circle_points)


## Draws a centre-first fan ([centre, rim0, rim1, ...]) as explicit triangles.
## We supply the indices ourselves instead of letting draw_colored_polygon
## triangulate, which fails ("triangulation failed") when rays bunch up near a
## wall and produce duplicate/collinear vertices. Degenerate triangles here just
## render nothing instead of erroring, so the mask never flickers off.
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


func _get_camera() -> Camera3D:
	if camera:
		return camera
	if player:
		return player.get_viewport().get_camera_3d()
	return null
