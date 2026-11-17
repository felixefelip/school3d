extends Node
## A door that leads to another scene: the apartment's front door goes down to
## the street and the building's lobby door goes back up. With E the screen
## fades to black, the other scene loads and the player appears at the
## Marker3D named `target_spawn` there (searched under the scene's root).
##
## travel() does the same from anywhere (GameClock uses it to put the player
## back in bed after sleeping).

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
	await travel(self, target_scene, target_spawn, fade_time)


## Fades the screen to black over `fade_time`, then loads `scene_path` with
## the player at the spawn point `spawn`. `host` keeps the fade on screen
## while it runs (it must stay in the tree until then).
static func travel(host: Node, scene_path: String, spawn: String, fade_time := 0.35) -> void:
	var fade := make_fade(host, 0.0)
	var tween := fade.create_tween()
	tween.tween_property(fade, "color:a", 1.0, fade_time)
	await tween.finished
	_arrival_spawn = spawn
	host.get_tree().change_scene_to_file(scene_path)


func _arrive(spawn_name: String) -> void:
	var root := owner if owner else get_tree().current_scene
	var spawn := root.find_child(spawn_name, true, false) as Node3D
	var player := root.get_node_or_null("Player") as Node3D
	if spawn and player:
		player.global_transform = spawn.global_transform
	var fade := make_fade(self, 1.0)
	var tween := fade.create_tween()
	tween.tween_property(fade, "color:a", 0.0, fade_time)
	tween.tween_callback(fade.get_parent().queue_free)


## A black rectangle over the whole screen, above the HUD, added to `host`.
static func make_fade(host: Node, alpha: float) -> ColorRect:
	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(0, 0, 0, alpha)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	host.add_child(layer)
	return rect
