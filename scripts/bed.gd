extends Node
## The player's bed: E goes to sleep and ends the day at any time (see
## GameClock.sleep()). She wakes up next to it the next morning.

## The bed (or a part of it); the player has to stand near it.
@export var target_path: NodePath
## From the bed's origin to the spot next to it.
@export var interaction_offset := Vector3.ZERO


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_point() -> Vector3:
	return (get_node(target_path) as Node3D).global_position + interaction_offset


func get_prompt() -> String:
	return "" if GameClock.is_sleeping() else "Go to sleep"


func interact(_by: Node3D) -> void:
	GameClock.sleep()
