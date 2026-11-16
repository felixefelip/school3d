extends Node
## A chair the player can sit on with E. One is created per chair by seats.gd.

var chair: Node3D
## Where the chair stands when nobody is using it.
var rest_transform: Transform3D


func setup(chair_node: Node3D) -> void:
	chair = chair_node
	rest_transform = chair.global_transform
	add_to_group("interactable")


func get_interaction_point() -> Vector3:
	return rest_transform.origin


func get_prompt() -> String:
	return "Sit"


func interact(by: Node3D) -> void:
	by.sit_on(self)
