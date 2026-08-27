extends PanelContainer

var drag := false
var delta := Vector2.ZERO

func _process(_delta: float) -> void:
	if drag:
		global_position = get_global_mouse_position() - delta

func _on_close_button_down() -> void:
	queue_free()

func _on_bar_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	if event.is_pressed():
		drag = true
		delta = get_global_mouse_position() - global_position
	else: drag = false
