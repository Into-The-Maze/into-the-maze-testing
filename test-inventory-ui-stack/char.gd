extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _ready() -> void:
	var inv = $Inventory
	var bandage = ITEM_INSTANCE_REGISTRY.create_instance(&"bandage")
	inv.auto_insert_item(bandage.id_unique)
	var mre = ITEM_INSTANCE_REGISTRY.create_instance(&"mre")
	inv.auto_insert_item(mre.id_unique)
	var medkit = ITEM_INSTANCE_REGISTRY.create_instance(&"medkit")
	inv.auto_insert_item(medkit.id_unique)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Open Inventory"):
		var panel = UI_MANAGER.open_panel(&"player_inventory")
		if !panel: return
		panel.content.inventory = $Inventory
