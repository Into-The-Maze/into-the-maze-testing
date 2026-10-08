extends Node
class_name Conditions

signal value_changed (key: StringName, old: float, new: float)
signal status_applied (instance: StatusInstance)
signal status_removed (instance: StatusInstance)
signal meter_empty (id: StringName)

@export var profile: ConditionsProfile
@export var tickrate: float = 10.0

var _ticker := 0.0

var _stats: Dictionary[StringName, Stat] = {}
var _meters: Dictionary[StringName, Meter] = {}
var _modifiers: Dictionary[StringName, Array] = {}
var _statuses: Array[StatusInstance] = []
var _rules: Dictionary[Rule, StatusInstance] = {}
var _immunities: Array[StringName] = []

static func of(entity: Node) -> Conditions:
	return entity.get_node_or_null(^"Conditions") as Conditions

func _ready() -> void:
	for stat_def in profile.stats:
		_stats[stat_def.id] = Stat.new(stat_def)

	for meter_def in profile.meters:
		_meters[meter_def.id] = Meter.new(meter_def)

		var meter_max := StatDef.new()
		meter_max.base = meter_def.base_max_value
		meter_max.min_value = meter_def.min_value
		_stats[StringName("%s.max"%meter_def.id)] = Stat.new(meter_max)

		var meter_rate := StatDef.new()
		meter_rate.base = meter_def.base_rate
		_stats[StringName("%s.rate"%meter_def.id)] = Stat.new(meter_rate)

	for passive in profile.passive_modifiers:
		add_modifier(passive, self)

	_immunities.append_array(profile.immune_tags)

	for start_status in profile.starting_statuses:
		apply_status(start_statuses)

func _physics_process(delta: float) -> void:
	_ticker += delta
	var step := 1.0 / tickrate
	while _ticker >= step:
		_ticker -= step
		_tick(step)

func _tick(delta: float) -> void:
	_tick_stats()
	_tick_statuses(delta)
	_tick_meters(delta)
	_tick_rules()

### Querying ###

