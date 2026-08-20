extends Node

var is_open = false
var classes: Dictionary = {}
var entities: Dictionary = {}
var history: Array[String] = []
var history_index: int = -1

const COMMAND_HELP := {
	"help": "help - list available commands",
	"scall": "scall ClassName::method arg1 arg2 ... - call a static method on a class",
	"dcall": "dcall key::method arg1 arg2 ... - call a method on a registered instance",
	"echo": "echo <text> - print text back to the console",
	"clear": "clear - clear console",
	"scene": "scene - get current scene name",
	"tree": "tree - get scene tree",
	"list": "list - print class names and registered entities",
	"methods": "methods name - print callable methods on name"
}

### API ###
func register(key: String, instance: Object) -> void:
	entities[key] = instance

func unregister(key: String) -> void:
	if entities.has(key):
		entities.erase(key)

### Setup ###
func _ready() -> void:
	_build_class_index()
	help()

func _build_class_index() -> void:
	for entry in ProjectSettings.get_global_class_list():
		classes[entry["class"]] = entry["path"]

### Toggle ###
func _input(event: InputEvent) -> void:
	if !event.is_action_pressed("toggle_dev_console"): return
	get_viewport().set_input_as_handled()
	open() if !is_open else close()

func open():
	$Container.visible = true
	is_open = true
	$Container/V/Input.grab_focus()

func close():
	$Container.visible = false
	is_open = false

### Interaction ###
func _on_input_text_submitted(new_text: String) -> void:
	push(">> %s" % new_text)
	var command = new_text.strip_edges().split(" ", true, 1)
	var opcode = command[0]
	var operand
	if len(command) > 1:
		operand = command[1]
	history.append(new_text)
	history_index = -1
	match opcode:
		"scall": scall(operand)
		"dcall": dcall(operand)
		"echo": echo(operand)
		"help": help()
		"methods": methods(operand)
		"clear": clear()
		"scene": scene()
		"tree": tree()
		"list": list()

		_: push("ERROR: Invalid command")
	$Container/V/Input.text = ""

func push(text: String):
	$Container/V/History.text += text + '\n'

func scall(input: String):
	input = input.strip_edges()
	var head_and_rest := input.split(" ", false, 1)
	var head := head_and_rest[0]
	var raw_args := head_and_rest[1] if head_and_rest.size() > 1 else ""

	if not "::" in head:
		push("ERROR: Expected class_name::function")
		return

	var split := head.split("::")
	var class_name_str := split[0]
	var method_name := split[1]
	var a := _args(raw_args)

	if !classes.has(class_name_str):
		push("ERROR: Class %s not found" % class_name_str)
		return

	var script: Script = load(classes[class_name_str])
	var callable := Callable(script, method_name)

	if !callable.is_valid():
		push("ERROR: Static method %s not found in %s" % [method_name, class_name_str])
		return

	var result = callable.callv(a)
	push(str(result))

func dcall(input: String):
	input = input.strip_edges()
	var head_and_rest = input.split(" ", false, 1)
	var head = head_and_rest[0]
	var raw_args = head_and_rest[1] if head_and_rest.size() > 1 else ""

	if not "::" in head:
		push("ERROR: Expected instance_key::function")
		return

	var split = head.split("::")
	var key_str = split[0]
	var method_name = split[1]
	var a = _args(raw_args)

	if !entities.has(key_str):
		push("ERROR: No registered instance '%s'" % key_str)
		return

	var target: Object = entities[key_str]
	if !is_instance_valid(target):
		push("ERROR: Instance '%s' is no longer valid" % key_str)
		entities.erase(key_str)
		return

	var callable = Callable(target, method_name)
	if !callable.is_valid():
		push("ERROR: Method %s not found on %s" % [method_name, key_str])
		return

	var result = callable.callv(a)
	push(str(result))

func echo(input: String):
	push(input)

func help():
	push("Available commands:")
	for cmd in COMMAND_HELP.keys():
		push("  %s" % COMMAND_HELP[cmd])

func methods(target_name: String) -> void:
	var target = null
	var source_label := ""

	if entities.has(target_name):
		target = entities[target_name]
		source_label = "instance"
	elif classes.has(target_name):
		target = load(classes[target_name])
		source_label = "static"
	else:
		push("ERROR: No class or registered instance '%s'" % target_name)
		return

	push("Methods on %s (%s):" % [target_name, source_label])

	var seen := {}
	for method in target.get_method_list():
		var mname: String = method["name"]
		if mname.begins_with("_"):
			continue  # skip private/engine-internal methods
		if seen.has(mname):
			continue
		seen[mname] = true

		var arg_names: Array = []
		for arg in method["args"]:
			arg_names.append(arg["name"])
		push("  %s(%s)" % [mname, ", ".join(arg_names)])

func clear():
	$Container/V/History.text = ""

func scene():
	push(get_tree().current_scene.name)

func tree() -> void:
	var root := get_tree().current_scene
	push("Scene tree (%s):" % root.name)
	_print_tree_recursive(root, 0)

func list():
	push(str(classes) + '\n' + str(entities))


### Util ###
func _args(raw: String) -> Array:
	var tokens = _tokenize(raw)
	var a: Array = []
	for token in tokens:
		a.append(_coerce_token(token))
	return a

func _tokenize(raw: String) -> Array:
	var tokens: Array = []
	var current = ""
	var in_quotes = false
	var i = 0
	while i < raw.length():
		var c := raw[i]
		if c == "\"":
			in_quotes = not in_quotes
		elif c == " " and not in_quotes:
			if current != "":
				tokens.append(current)
				current = ""
		else:
			current += c
		i += 1
	if current != "":
		tokens.append(current)
	return tokens

func _coerce_token(token: String) -> Variant:
	match token:
		"true": return true
		"false": return false
		"null": return null
		token when token.is_valid_int(): return token.to_int()
		token when token.is_valid_float(): return token.to_float()

		_: return token

func _print_tree_recursive(node: Node, depth: int) -> void:
	var indent := "  ".repeat(depth)
	var line := "%s%s (%s)" % [indent, node.name, node.get_class()]
	push(line)
	for child in node.get_children():
		_print_tree_recursive(child, depth + 1)

### Navigation ###
func _on_input_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			navigate_history(1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			navigate_history(-1)
			get_viewport().set_input_as_handled()

func navigate_history(direction: int) -> void:
	if history.is_empty():
		return
	if direction > 0:
		history_index = min(history_index + 1, history.size() - 1)
	else:
		history_index = max(history_index - 1, -1)

	if history_index == -1:
		$Container/V/Input.text = ""
	else:
		$Container/V/Input.text = history[history.size() - 1 - history_index]

	$Container/V/Input.caret_column = $Container/V/Input.text.length()
