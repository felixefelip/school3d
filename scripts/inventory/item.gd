class_name Item
extends Resource
## Something the player can carry in an inventory slot. Each item is a .tres
## file under res://items/. Storages hand out copies (see storage.gd), so
## every piece of clothing keeps its own clean/dirty state.

## Where a piece of clothing is worn. NONE: not clothing.
enum Slot { NONE, HEAD, TOP, LEGS, FEET }

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export_multiline var description: String
@export var slot := Slot.NONE
## How it looks when worn (see outfit.gd). In order of priority:
##  - keep_original: the character's own piece for that slot (the uniform).
##  - model_scene: an extra model; skinned meshes for the body, or a scene
##    attached to the head bone for HEAD items.
##  - otherwise the character's own piece, painted in `color`.
@export var keep_original := false
@export var model_scene: PackedScene
@export var color := Color.WHITE
## Dirty clothes can't be worn until washed in the washing machine.
@export var dirty := false
## Seconds worn since it was last washed.
var worn_seconds := 0.0


func is_clothing() -> bool:
	return slot != Slot.NONE
