extends LayerDef
class_name DebugLayer

@export var width: int
@export var height: int
@export var depth: int

func init_maze() -> Array:
	_initialise_array()
	return _maze

func print_maze() -> void:
	for z in depth:
		print("### Depth %s ###" % z)
		var s = ""
		for y in height:
			for x in width:
				s += _maze[z][y][x].print_char
			s += "\n"
		print(s)

func _initialise_array() -> bool:
	_maze = []
	for z in depth:
		_maze.append([])
		for y in height:
			_maze[z].append([])
			for x in width:
				_maze[z][y].append(Cell.new(Cell.TYPES.NESW))
	return true

func _place_rooms() -> bool:
	return true

func _generate_corridors() -> bool:
	return true

func _rotate_room(room: RoomDefinition) -> RoomDefinition:
	return RoomDefinition.new()

