# Inventory, Items, and UI Manager
## Items
The item system is composed of 5 parts:
1. `res://autoload/ITEM_DEFINITION_REGISTRY.gd`;
2. `res://autoload/ITEM_INSTANCE_REGISTRY.gd`;
3. `res://item/item_definition.gd`;
4. `res://item/item_instance.gd`;
5. `res://item/item_component.gd`.
### Item Definitions
Item definitions are defined by the resource extension `res://item/item_definition.gd`. Item definitions are unchanging definitions of base items, containing information about items that never changes. This includes their:
- StringName id: unique identifier for the item;
- String name: Display name for the item;
- String description: flavour text for the item;
- Texture2D item_2d: icon which is displayed in the inventory;
- PackedScene item_3d: item which is spawned in the world when dropped or otherwise needed;
- Vector2i grid_size: inventory size in cells;
- int max_stack_size: maximum number this item can stack to, if stackable. Redundant for non-stackable items;
- bool is_stackable: flag for stackable items;

Definitions are of a **type**, which are found in `res://resource/item_definition_types/`. These types classify similar items, such as food, medical, or melee.
#### Adding new item definitions
1. Check if your item falls under an existing type. Make a type if not.
2. Make a new resource in the `resource/item_definition` folder. Select the appropriate definition type.
3. Fill in the id, icon, and grid size as minimum information.
4. The item will be automatically registered so long as it is in the apropriate place.
### Definition Registry
The definition registry is an autoload script. It contains a dictionary of StringName ids against the item definitions.

Item definitions are automatically loaded from the path `DEFINITION_PATH`, set here as `res://resource/item_definition/`. When the game begins, the registry loads all definitions from the defined path into the dictionary, and ensures they have a unique id.

The registry exposes an API for interacting with definitions:
- `get_definition`: returns a definition given an id;
- `has_definition`: checks if a definition id exists;
- `get_all_ids`: returns a list of all item definition ids.
### Instance Registry
The instance registry is an autoload script which manages items existing in the world. Item instances are assigned a UUID when created, and tracked in a dictionary.

The registry exposes an API for instancing:
- `create_instance`: instances an item of a given definition;
- `destroy_instance`: removes an instance from the dictionary;
- `get_instance`: returns an instance given a UUID;
- `has_instance`: checks if a given UUID exists;
- `get_all_instances`: returns a list of all item instances.
### Item Instances
An item instance is an item which exists in the world. It has a UUID, definition id, quantity, and contains a list of components. It exposes a simple API for interacting with the component list.
### Item Components
Item components are small scripts which track dynamic state on an item instance. Components have a key used to interact with them, and variables containing the dynamic state they concern.

Here, a durability_component is given as example. The melee_weapon_definition contains a field for max_durability, and the component tracks the current durability and exposes functions for interacting with the dynamic value.

Components can be added to item instances at runtime by creating a new() one, then adding it to the instance with its API.

You may add a new component by extending ItemComponent and implementing some functionality

## Inventory


## UI Manager
