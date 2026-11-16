extends Node
## Opens and closes a hinged door. The door node's origin must sit on the hinge.
## The player finds it through the "interactable" group and calls interact().

@export var door_path: NodePath
## How far the door turns when it opens. The sign picks the side it swings
## to, and it always swings to that same side.
@export var open_angle_degrees: float = 90.0
@export var starts_open: bool = false
## Time to open or close (s).
@export var duration: float = 0.6
## From the hinge to the middle of the closed door, in the door's local space.
## Used to measure how close the player is.
@export var center_offset: Vector3 = Vector3(-0.4, 1.0, 0.0)

var is_open := false

var _door: Node3D
var _closed_rotation: float
var _closed_transform: Transform3D
var _tween: Tween


func _ready() -> void:
	_door = get_node(door_path)
	_closed_rotation = _door.rotation.y
	_closed_transform = _door.global_transform
	if starts_open:
		is_open = true
		_door.rotation.y = _open_rotation()
	add_to_group("interactable")


func get_interaction_point() -> Vector3:
	return _closed_transform * center_offset


func get_prompt() -> String:
	return "Close door" if is_open else "Open door"


func interact(_by: Node3D) -> void:
	is_open = not is_open
	var target := _open_rotation() if is_open else _closed_rotation
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_door, "rotation:y", target, duration)


func _open_rotation() -> float:
	return _closed_rotation + deg_to_rad(open_angle_degrees)
