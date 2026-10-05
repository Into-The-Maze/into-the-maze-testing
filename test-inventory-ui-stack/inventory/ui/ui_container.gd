extends PanelContainer
class_name UIContainer

var drag := false
var delta := Vector2.ZERO
var key := &""
var selected := false

var content:
	get:
		return $V.get_child(-1)

func _process(_delta: float) -> void:
	if drag:
		global_position = get_global_mouse_position() - delta

func _on_close_button_down() -> void:
	queue_free()

func _on_bar_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	if event.is_pressed():
		if !selected:
			UI_MANAGER.UI_CONTAINER_SELECTED.emit(key)
			selected = true
		drag = true
		delta = get_global_mouse_position() - global_position
	else:
		drag = false
		selected = false

func _on_gui_input(event: InputEvent) -> void:
	if event is not InputEventMouseButton: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	if event.is_pressed():
		if !selected:
			UI_MANAGER.UI_CONTAINER_SELECTED.emit(key)
			selected = true
	else:
		selected = false
