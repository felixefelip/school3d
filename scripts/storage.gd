extends Node
## Furniture that holds items, like the bedroom wardrobe. The player opens it
## with E and drags items between it and the hotbar.

@export var title := "Storage"
## The furniture itself; the player has to stand near it.
@export var target_path: NodePath
## From the furniture's origin to the spot in front of it.
@export var interaction_offset := Vector3.ZERO
@export var slot_count := 12
## What it holds when the scene starts, from the first slot on.
@export var starting_items: Array[Item] = []

var inventory: Inventory


func _ready() -> void:
	inventory = Inventory.create(slot_count)
	for i in mini(starting_items.size(), slot_count):
		inventory.items[i] = starting_items[i]
	add_to_group("interactable")


func get_interaction_point() -> Vector3:
	return (get_node(target_path) as Node3D).global_position + interaction_offset


func get_prompt() -> String:
	return "Open " + title.to_lower()


func interact(by: Node3D) -> void:
	by.open_storage(self)
