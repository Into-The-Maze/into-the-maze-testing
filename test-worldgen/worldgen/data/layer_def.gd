@abstract
class_name LayerDef extends Resource

@export var layer_number: int
@export var rooms: Array[RoomDefinition]

@abstract
func init_maze() -> Array[Array]

@abstract
func _initialise_array()

@abstract
func _place_rooms()

@abstract
func _generate_corridors()

