extends Node
## Friendship points with the NPCs the player can get to know (the ones with a
## name, see npc_student.gd). Autoload (Relationships), so the points carry
## over from one scene to another.
##
## Talking to one of them changes the points by how the player looks: in clean
## clothes they're nice to her (+1), with any dirty piece on they aren't (-1).
## The points change at most once per NPC every `talk_cooldown` seconds, so
## pressing E over and over doesn't farm them; they still answer meanwhile.

signal changed(npc_id: String, points: int)

## Seconds before talking to the same NPC changes the points again.
var talk_cooldown := 180.0
## Lowest number of points; friendship doesn't go below it.
const MIN_POINTS := 0

## Points per NPC id.
var points := {}
## When the points of each NPC last changed (seconds since the game started).
var _last_change := {}
var _dialogue_box: Control


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_dialogue_box = preload("res://scripts/ui/dialogue_box.gd").new()
	layer.add_child(_dialogue_box)


func get_points(npc_id: String) -> int:
	return points.get(npc_id, 0)


## True when nothing she wears is dirty (an empty slot counts as clean).
func is_outfit_clean() -> bool:
	for item: Item in PlayerInventory.equipment.items:
		if item and item.dirty:
			return false
	return true


func can_change(npc_id: String) -> bool:
	return not _last_change.has(npc_id) or _now() - _last_change[npc_id] >= talk_cooldown


## Adds `amount` (may be negative) and returns the actual change, which is
## smaller when the points are already at MIN_POINTS.
func change_points(npc_id: String, amount: int) -> int:
	var before := get_points(npc_id)
	var after := maxi(before + amount, MIN_POINTS)
	points[npc_id] = after
	_last_change[npc_id] = _now()
	if after != before:
		changed.emit(npc_id, after)
	return after - before


## The player talks to an NPC: picks a nice or a rude line by her clothes,
## changes the points (unless they changed recently) and shows the dialogue.
## Returns the change in points.
func talk(npc_id: String, npc_name: String, friendly_lines: PackedStringArray, rude_lines: PackedStringArray) -> int:
	var clean := is_outfit_clean()
	var lines := friendly_lines if clean else rude_lines
	var line := lines[randi() % lines.size()] if not lines.is_empty() else ""
	var recently := not can_change(npc_id)
	var change := 0 if recently else change_points(npc_id, 1 if clean else -1)
	_dialogue_box.show_line(npc_name, line, change, get_points(npc_id), recently)
	return change


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0
