extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _physics_process(delta: float) -> void:

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	var mouse = get_viewport().get_mouse_position()
	var cam = $Camera3D
	var origin = cam.project_ray_origin(mouse)
	var normal = cam.project_ray_normal(mouse)
	var plane = Plane(Vector3.UP, global_position.y)
	var target = plane.intersects_ray(origin, normal)
	look_at(target)
	cam.position.x = position.x
	cam.position.z = position.z
