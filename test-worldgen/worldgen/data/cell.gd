extends RefCounted
class_name Cell

enum TYPES { N, E, S, W, NE, NS, NW, ES, EW, SW, NES, NEW, NSW, ESW, NESW,
			ROOM, WALL, STAIR, ENTRYN, ENTRYE, ENTRYS, ENTRYW }

var print_char: String
var type: TYPES:
	get: return type
	set(value): type = value; set_print_char();

func _init(set_type: TYPES) -> void:
	type = set_type

func set_print_char():
	match type:
		TYPES.N:      print_char = "╵"
		TYPES.E:      print_char = "╶"
		TYPES.S:      print_char = "╷"
		TYPES.W:      print_char = "╴"
		TYPES.NE:     print_char = "└"
		TYPES.NS:     print_char = "│"
		TYPES.NW:     print_char = "┘"
		TYPES.ES:     print_char = "┌"
		TYPES.EW:     print_char = "─"
		TYPES.SW:     print_char = "┐"
		TYPES.NES:    print_char = "├"
		TYPES.NEW:    print_char = "┴"
		TYPES.NSW:    print_char = "┤"
		TYPES.ESW:    print_char = "┬"
		TYPES.NESW:   print_char = "┼"
		TYPES.ROOM:   print_char = "X"
		TYPES.WALL:   print_char = "█"
		TYPES.STAIR:  print_char = "S"
		TYPES.ENTRYN: print_char = "@"
		TYPES.ENTRYE: print_char = "@"
		TYPES.ENTRYS: print_char = "@"
		TYPES.ENTRYW: print_char = "@"

