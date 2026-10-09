extends Label

@export var c: Conditions

var stamina = 0.0
var temperature = 0.0
var is_wet = true

func _ready() -> void:
	c.value_changed.connect(_on_meter_changed)
	c.status_removed.connect(_on_status_decayed)

func _process(_delta: float) -> void:
	text = "stamina = %s\ntemperature=%s\nwet=%s"%[stamina,temperature,is_wet]

func _on_meter_changed(k, _o, v):
	match k:
		&"stamina": stamina = v
		&"temperature": temperature = v

func _on_status_decayed(status):
	if status.key() == &"wet": is_wet = false
