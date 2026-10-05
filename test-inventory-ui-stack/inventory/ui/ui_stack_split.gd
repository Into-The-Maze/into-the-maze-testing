extends Control
class_name UISplitStack

signal confirmed (quantity: int)
signal cancelled ()

@onready var box: PanelContainer = %Dialogue
@onready var slider: HSlider = %Slider
@onready var spinbx: SpinBox = %Spin

var _quantity_to_move := 0

func prepare(max_amount: int, at: Vector2) -> void:
	slider.min_value = 1
	slider.max_value = max_amount
	slider.step = 1

	spinbx.min_value = 1
	spinbx.max_value = max_amount

	_set_quantity(ceili(max_amount / 2.0))
	slider.grab_focus()

	await get_tree().process_frame
	var view := get_viewport().get_visible_rect()
	box.position = (at - box.size * 0.5).clamp(view.position, view.end - box.size)

func _set_quantity(quantity: int) -> void:
	_quantity_to_move = clampi(quantity, int(slider.min_value), int(slider.max_value))
	slider.set_value_no_signal(quantity)
	spinbx.set_value_no_signal(quantity)

func _on_spin_value_changed(value: float) -> void:
	_set_quantity(int(value))

func _on_slider_value_changed(value: float) -> void:
	_set_quantity(int(value))

func _on_confirm_pressed() -> void:
	confirmed.emit(_quantity_to_move)
	queue_free()

func _on_cancel_pressed() -> void:
	cancelled.emit()
	queue_free()

