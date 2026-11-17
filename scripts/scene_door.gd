extends Node
## A door that leads to another scene: the apartment's front door goes down to
## the street and the building's lobby door goes back up. With E the screen
## fades to black, the other scene loads and the player appears at the
## Marker3D named `target_spawn` there (searched under the scene's root).

## Where the player arrives in the scene being loaded. The first SceneDoor of
## that scene to get ready moves the player there and clears it.
static var _arrival_spawn := ""

## The door mesh; the player has to stand near it.
@export var door_path: NodePath
@export_file("*.tscn") var target_scene: String
@export var target_spawn: String
@export var prompt := "Go out"
## From the door's origin to the spot in front of it, in the door's local space.
@export var center_offset := Vector3(0, 0, 0.5)
@export var fade_time := 0.35

var _leaving := false


func _ready() -> void:
	add_to_group("interactable")
	if _arrival_spawn != "":
		var spawn_name := _arrival_spawn
		_arrival_spawn = ""
		_arrive.call_deferred(spawn_name)


func get_interaction_point() -> Vector3:
	return (get_node(door_path) as Node3D).global_transform * center_offset


func get_prompt() -> String:
	return "" if _leaving else prompt


func interact(_by: Node3D) -> void:
	if _leaving:
		return
	_leaving = true
	var fade := _make_fade(0.0)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, fade_time)
	await tween.finished
	_arrival_spawn = target_spawn
	get_tree().change_scene_to_file(target_scene)


func _arrive(spawn_name: String) -> void:
	var root := owner if owner else get_tree().current_scene
	var spawn := root.find_child(spawn_name, true, false) as Node3D
	var player := root.get_node_or_null("Player") as Node3D
	if spawn and player:
		player.global_transform = spawn.global_transform
	var fade := _make_fade(1.0)
	var tween := fade.create_tween()
	tween.tween_property(fade, "color:a", 0.0, fade_time)
	tween.tween_callback(fade.get_parent().queue_free)


## A black rectangle over the whole screen, above the HUD.
func _make_fade(alpha: float) -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, alpha)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	add_child(layer)
	return rect
