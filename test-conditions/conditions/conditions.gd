extends Node
class_name Conditions

signal value_changed (key: StringName, old_value: float, new_value: float)
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
var _active_rules: Dictionary[Rule, StatusInstance] = {}
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
		apply_status(start_status)

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
func has_key(key: StringName) -> bool:
	return _stats.has(key) or _meters.has(key)

func get_value(key: StringName) -> float:
	if _meters.has(key): return _meters[key].current
	if _stats.has(key): return _stats[key].value
	return 0.0

func has_status(id: StringName) -> bool:
	for s in _statuses:
		if s.def.id == id:
			return true
	return false

func has_status_tag(tag: StringName) -> bool:
	for s in _statuses:
		if tag in s.def.tags:
			return true
	return false

### Modifiers ###
func add_modifier(def: ModifierDef, source: Object, context: StringName = &"") -> void:
	var key := StringName(String(def.key).replace("{context}", context))
	if !_modifiers.has(key):
		_modifiers[key] = []
	_modifiers[key].append(ActiveModifier.new(def, source))

func remove_modifiers_from_source(source: Object) -> void:
	for key in _modifiers:
		_modifiers[key] = _modifiers[key].filter(func(mod: ActiveModifier):
			return mod.source != source
		)

### Ticks ###
func _tick_stats() -> void:
	for key in _stats:
		var stat := _stats[key]
		var old_value := stat.value
		if stat.recalculate(_modifiers.get(key, []), self):
			value_changed.emit(key, old_value, stat.value)

func _tick_statuses(delta: float):
	for status_instance: StatusInstance in _statuses.duplicate():
		status_instance.def._on_tick(self, status_instance, delta)
		for e in status_instance.def.effects:
			e.on_tick(self, status_instance, delta)

		if status_instance.def.duration < 0.0: continue

		var decay := get_value(StringName("status.%s.decay"%status_instance.def.id))
		status_instance.remaining -= delta * decay
		if status_instance.remaining <= 0.0:
			remove_status(status_instance)

func _tick_meters(delta: float):
	for id in _meters:
		var meter := _meters[id]
		var old_value := meter.current
		var max_value := _stats[StringName("%s.max"%id)].value
		var rate := _stats[StringName("%s.rate"%id)].value
		meter.current = clampf(meter.current + rate * delta, meter.def.min_value, max_value)

		if meter.current != old_value:
			value_changed.emit(id, old_value, meter.current)
			if meter.current <= meter.def.min_value:
				meter_empty.emit(id)

func _tick_rules():
	for rule in profile.rules:
		var active: StatusInstance = _active_rules.get(rule)
		if active == null:
			if rule.enter_condition.evaluate(self):
				_active_rules[rule] = apply_status(rule.status, rule.context)
		else:
			if !(active in _statuses):
				_active_rules.erase(rule)
				continue
			var exit := false
			if rule.exit_condition:
				exit = rule.exit_condition.evaluate(self)
			else:
				exit = not rule.enter_condition.evaluate(self)
			if exit:
				remove_status(active)
				_active_rules.erase(rule)

### Status ###
func apply_status(def: StatusDef, context: StringName = &"", source: Node = null) -> StatusInstance:
	for tag in def.tags:
		if tag in _immunities:
			return null

	for status_instance in _statuses:
		if status_instance.def == def and status_instance.context == context:
			match def.stacking:
				StatusDef.Stacking.IGNORE:
					return status_instance
				StatusDef.Stacking.REFRESH:
					status_instance.remaining = def.duration
					return status_instance
				StatusDef.Stacking.EXTEND:
					status_instance.remaining += def.duration
					return status_instance
				StatusDef.Stacking.STACK:
					if status_instance.stacks < def.max_stacks:
						status_instance.stacks += 1
						_add_status_modifiers(status_instance)
					return status_instance

	var new := StatusInstance.new()
	new.def = def
	new.context = context
	new.remaining = def.duration
	new.source = source
	_statuses.append(new)

	var decay_stat_key := StringName("status.%s.decay"%def.id)
	if !_stats.has(decay_stat_key):
		var stat_def := StatDef.new()
		stat_def.base = 1.0
		_stats[decay_stat_key] = Stat.new(stat_def)

	_add_status_modifiers(new)
	for e in def.effects:
		e.on_apply(self, new)
	status_applied.emit(new)

	return new

func _add_status_modifiers(status_instance: StatusInstance) -> void:
	for mod in status_instance.def.modifiers:
		add_modifier(mod, status_instance, status_instance.context)

func remove_status(status_instance: StatusInstance) -> void:
	for e in status_instance.def.effects:
		e.on_remove(self, status_instance)

	remove_modifiers_from_source(status_instance)
	_statuses.erase(status_instance)
	status_removed.emit(status_instance)

func remove_status_by_tag(tag: StringName) -> void:
	for status_instance: StatusInstance in _statuses.duplicate():
		if tag in status_instance.def.tags:
			remove_status(status_instance)
