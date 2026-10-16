@abstract
class_name LayerDef extends Resource

@export var layer_number: int
@export var rooms: Array[RoomDefinition]

var _maze := []

@abstract
func init_maze() -> Array
@abstract
func _initialise_array() -> bool
@abstract
func _place_rooms() -> bool
@abstract
func _generate_corridors() -> bool
@abstract
func print_maze() -> void

