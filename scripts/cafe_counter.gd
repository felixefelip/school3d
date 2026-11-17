extends Node
## The café counter: with E the player orders a coffee and gets a cup in her
## hotbar (if there's room).

## Where the player stands to order.
@export var target_path: NodePath
@export var interaction_offset := Vector3.ZERO
## What she gets.
@export var item: Item


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_point() -> Vector3:
	return (get_node(target_path) as Node3D).global_position + interaction_offset


func get_prompt() -> String:
	return "Order a coffee" if PlayerInventory.inventory.items.has(null) else "Order a coffee (inventory full)"


func interact(_by: Node3D) -> void:
	PlayerInventory.inventory.add(item.duplicate())
