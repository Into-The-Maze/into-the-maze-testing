extends Node2D

@export var player: CharacterBody3D
@export var ray_count: int = 90
@export var vision_radius: float = 12.0
@export var darkness_color: Color = Color(0.0, 0.0, 0.0, 0.92)
@export var ray_collision_mask: int = 1
@export var shader_rect: ColorRect

var _lit_points: Array[Vector2] = []

func _process(_delta: float) -> void:
	_lit_points = _cast_rays()
	_update_shader()
	queue_redraw()

func _cast_rays() -> Array[Vector2]:
	var camera := get_viewport().get_camera_3d()
	if not camera or not player:
		return []

	var origin := player.global_position
	var space_state := get_viewport().get_world_3d().direct_space_state

	# Collect angles — uniform sweep plus flanking rays at each wall hit
	var angles: Array[float] = []
	for i in ray_count:
		var angle := (float(i) / float(ray_count)) * TAU
		angles.append(angle)

		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var query := PhysicsRayQueryParameters3D.create(
			origin, origin + dir * vision_radius
		)
		query.collision_mask = ray_collision_mask
		query.exclude = [player.get_rid()]
		var result := space_state.intersect_ray(query)

		if not result.is_empty():
			var hit_angle := atan2(
				result.position.z - origin.z,
				result.position.x - origin.x
			)
			angles.append(hit_angle - 0.0002)
			angles.append(hit_angle + 0.0002)

	angles.sort()

	var screen_points: Array[Vector2] = []
	var prev := Vector2(-99999, -99999)

	for angle in angles:
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var query := PhysicsRayQueryParameters3D.create(
			origin, origin + dir * vision_radius
		)
		query.collision_mask = ray_collision_mask
		query.exclude = [player.get_rid()]
		var result := space_state.intersect_ray(query)

		var world_hit: Vector3
		if not result.is_empty():
			world_hit = result.position
		else:
			world_hit = origin + dir * vision_radius

		var screen_pos := camera.unproject_position(world_hit)
		if screen_pos.distance_to(prev) > 1.5:
			screen_points.append(screen_pos)
			prev = screen_pos

	return screen_points

func _update_shader() -> void:
	if not shader_rect:
		return
	var camera := get_viewport().get_camera_3d()
	if not camera or not player:
		return

	var screen_size := get_viewport().get_visible_rect().size
	var screen_pos := camera.unproject_position(player.global_position)
	var mat := shader_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("player_screen_pos", screen_pos / screen_size)
		mat.set_shader_parameter("screen_size", screen_size)

func _draw() -> void:
	if _lit_points.size() < 3:
		return

	var screen_size := get_viewport().get_visible_rect().size
	var sw := screen_size.x
	var sh := screen_size.y

	var player_screen := Vector2(sw * 0.5, sh * 0.5)
	if get_viewport().get_camera_3d() and player:
		player_screen = get_viewport().get_camera_3d().unproject_position(
			player.global_position
		)

	var n := _lit_points.size()
	for i in n:
		var a := _lit_points[i]
		var b := _lit_points[(i + 1) % n]

		var da := a.distance_to(player_screen)
		var db := b.distance_to(player_screen)

		var cam := get_viewport().get_camera_3d()
		if not cam:
			continue

		var screen_radius := _estimate_screen_radius(player_screen, cam)

		var a_is_wall := da < screen_radius * 0.98
		var b_is_wall := db < screen_radius * 0.98

		if a_is_wall or b_is_wall:
			var edge_a := _extend_to_screen_edge(player_screen, a, sw, sh)
			var edge_b := _extend_to_screen_edge(player_screen, b, sw, sh)

			var tri := PackedVector2Array([a, edge_a, edge_b, b])
			draw_colored_polygon(tri, darkness_color)

			_fill_screen_edge_gap(player_screen, edge_a, edge_b, sw, sh)

func _estimate_screen_radius(player_screen: Vector2, cam: Camera3D) -> float:
	var origin := player.global_position
	var test_point := origin + Vector3(vision_radius, 0, 0)
	var test_screen := cam.unproject_position(test_point)
	return test_screen.distance_to(player_screen)

func _extend_to_screen_edge(origin: Vector2, point: Vector2, sw: float, sh: float) -> Vector2:
	var dir := (point - origin).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	# March far enough to guarantee we exit the screen
	var far := origin + dir * (sw + sh) * 2.0
	return _clamp_to_screen(origin, far, sw, sh)

func _clamp_to_screen(from: Vector2, to: Vector2, sw: float, sh: float) -> Vector2:
	var d := to - from
	var t := 1.0

	if d.x != 0:
		if d.x > 0:
			t = min(t, (sw - from.x) / d.x)
		else:
			t = min(t, (0.0 - from.x) / d.x)
	if d.y != 0:
		if d.y > 0:
			t = min(t, (sh - from.y) / d.y)
		else:
			t = min(t, (0.0 - from.y) / d.y)

	return from + d * t

func _fill_screen_edge_gap(origin: Vector2, edge_a: Vector2, edge_b: Vector2, sw: float, sh: float) -> void:
	var corners := [
		Vector2(0, 0), Vector2(sw, 0),
		Vector2(sw, sh), Vector2(0, sh)
	]

	var angle_a := (edge_a - origin).angle()
	var angle_b := (edge_b - origin).angle()

	var gap_corners: Array[Vector2] = []
	for corner in corners:
		var angle_c = (corner - origin).angle()
		if _angle_between(angle_a, angle_b, angle_c):
			gap_corners.append(corner)

	if gap_corners.size() > 0:
		var fill := PackedVector2Array()
		fill.append(origin)
		fill.append(edge_a)
		for c in gap_corners:
			fill.append(c)
		fill.append(edge_b)
		draw_colored_polygon(fill, darkness_color)

func _angle_between(a: float, b: float, c: float) -> bool:
	a = fmod(a + TAU, TAU)
	b = fmod(b + TAU, TAU)
	c = fmod(c + TAU, TAU)
	if a <= b:
		return c >= a and c <= b
	else:
		return c >= a or c <= b

