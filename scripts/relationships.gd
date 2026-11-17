extends Node
## Friendship points with the NPCs the player can get to know (the ones with a
## name, see npc_student.gd). Autoload (Relationships), so the points carry
## over from one scene to another.
##
## Talking to one of them changes the points by how the player looks: in clean
## clothes they're nice to her (+1), with any dirty piece on they aren't (-1).
## Each NPC says one thing per day (GameClock): the first talk of the day
## picks the line, by how the player looks then, and talking again that day
## repeats it. The points also change only on that first talk, so pressing E
## over and over doesn't farm them.
##
## Gifts work like in Stardew Valley: holding an item in the hotbar, G gives
## it to the NPC (one gift per NPC per day, on top of the talk). Each NPC has
## items they love, like, dislike and hate (PEOPLE); anything else is
## neutral, and dirty clothes are hated by everyone. Once given, an NPC's
## taste for that item shows in the relationships list.

signal changed(npc_id: String, points: int)

## Everyone the player can get to know, so the relationships list (pause menu)
## shows them before she has met them. NPCs not listed here are added when
## they first appear (see register()).
## "model" is the character model, used for the face in the list.
## "loved", "liked", "disliked" and "hated" are their gift tastes (item ids).
const PEOPLE := {
	"bia": {
		"name": "Bia", "place": "Cafe Aroma", "model": "res://models/characters/blonde_student_walking.glb",
		"loved": ["coffee", "orange_juice"],
		"liked": ["apple", "yogurt", "banana", "cap"],
		"disliked": ["milk", "eggs"],
		"hated": ["cheese"],
	},
	"lucas": {
		"name": "Lucas", "place": "Cafe Aroma", "model": "res://models/characters/boy_student_walking.glb",
		"loved": ["banana", "milk"],
		"liked": ["cheese", "apple", "orange", "hoodie"],
		"disliked": ["yogurt", "coffee"],
		"hated": ["orange_juice"],
	},
}
## Gift tastes, from best to worst, with the points each one gives.
const TASTES := ["loved", "liked", "neutral", "disliked", "hated"]
const GIFT_POINTS := {"loved": 3, "liked": 2, "neutral": 1, "disliked": -1, "hated": -2}
## What NPCs say when they get a gift, by taste.
const GIFT_LINES := {
	"loved": ["Oh my gosh, I love this! Thank you so much!", "No way, this is my favorite! You're the best!"],
	"liked": ["Oh, thanks! I like this.", "That's nice of you, thank you!"],
	"neutral": ["Thanks.", "Oh, for me? Thanks."],
	"disliked": ["Um... thanks, I guess.", "Oh. This isn't really my thing..."],
	"hated": ["Ugh, what is this? Keep it.", "Seriously? I can't stand this."],
}
const ALREADY_GIFTED := "You already gave me something today. Thanks, though!"
## Hearts shown in the list; points above this still count.
const MAX_HEARTS := 10
## Friendship levels: the name of the highest level reached by the points.
const LEVELS := [[0, "Stranger"], [1, "Acquaintance"], [3, "Friend"], [6, "Good friend"], [10, "Best friend"]]

## Lowest number of points; friendship doesn't go below it.
const MIN_POINTS := 0

## Points per NPC id.
var points := {}
## Name and usual place per NPC id (PEOPLE plus the ones registered later).
var people := PEOPLE.duplicate(true)
## Ids of the NPCs the player has talked to.
var met := {}
## The day (GameClock.day_index()) the points of each NPC last changed.
var _last_change := {}
## What each NPC says today: [day, line].
var _todays_line := {}
## The day each NPC last got a gift.
var _last_gift := {}
## The gift tastes the player has found out, per NPC id: {item_id: [taste, item name]}.
var known_gifts := {}
var _dialogue_box: Control


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_dialogue_box = preload("res://scripts/ui/dialogue_box.gd").new()
	layer.add_child(_dialogue_box)


func get_points(npc_id: String) -> int:
	return points.get(npc_id, 0)


## Adds an NPC that isn't in PEOPLE yet, so it shows up in the list.
func register(npc_id: String, npc_name: String, place := "", model := "") -> void:
	if not people.has(npc_id):
		people[npc_id] = {"name": npc_name, "place": place, "model": model}


## The ids of everyone in the list, in the order they were added.
func list_people() -> Array:
	return people.keys()


static func level_name(value: int) -> String:
	var result: String = LEVELS[0][1]
	for level in LEVELS:
		if value >= level[0]:
			result = level[1]
	return result


## True when nothing she wears is dirty (an empty slot counts as clean).
func is_outfit_clean() -> bool:
	for item: Item in PlayerInventory.equipment.items:
		if item and item.dirty:
			return false
	return true


## False after the points of this NPC already changed today.
func can_change(npc_id: String) -> bool:
	return _last_change.get(npc_id, -1) != _today()


## Adds `amount` (may be negative) and returns the actual change, which is
## smaller when the points are already at MIN_POINTS.
func change_points(npc_id: String, amount: int) -> int:
	var before := get_points(npc_id)
	var after := maxi(before + amount, MIN_POINTS)
	points[npc_id] = after
	if after != before:
		changed.emit(npc_id, after)
	return after - before


## The player talks to an NPC: picks a nice or a rude line by her clothes,
## changes the points (unless they changed recently) and shows the dialogue.
## Returns the change in points.
func talk(npc_id: String, npc_name: String, friendly_lines: PackedStringArray, rude_lines: PackedStringArray) -> int:
	register(npc_id, npc_name)
	met[npc_id] = true
	var recently := not can_change(npc_id)
	var change := 0
	if not recently:
		var clean := is_outfit_clean()
		var lines := friendly_lines if clean else rude_lines
		_todays_line[npc_id] = [_today(), lines[randi() % lines.size()] if not lines.is_empty() else ""]
		change = change_points(npc_id, 1 if clean else -1)
		_last_change[npc_id] = _today()
	var line := todays_line(npc_id)
	_dialogue_box.show_line(npc_name, line, change)
	return change


## What the NPC says today; empty if the player hasn't talked to her today.
func todays_line(npc_id: String) -> String:
	var entry: Array = _todays_line.get(npc_id, [])
	return entry[1] if not entry.is_empty() and entry[0] == _today() else ""


## How the NPC feels about the item: one of TASTES.
func gift_taste(npc_id: String, item: Item) -> String:
	if item.is_clothing() and item.dirty:
		return "hated"
	var person: Dictionary = people.get(npc_id, {})
	for taste in ["loved", "liked", "disliked", "hated"]:
		if person.get(taste, []).has(item.id):
			return taste
	return "neutral"


## False after the NPC already got a gift today.
func can_gift(npc_id: String) -> bool:
	return _last_gift.get(npc_id, -1) != _today()


## The player gives `item` to an NPC: the points change by the NPC's taste
## and the NPC reacts. Returns {given, change, taste}; if the NPC already got
## a gift today she says so and `given` is false (the player keeps the item).
func give(npc_id: String, npc_name: String, item: Item) -> Dictionary:
	register(npc_id, npc_name)
	met[npc_id] = true
	if not can_gift(npc_id):
		_dialogue_box.show_line(npc_name, ALREADY_GIFTED, 0)
		return {"given": false, "change": 0, "taste": ""}
	var taste := gift_taste(npc_id, item)
	_last_gift[npc_id] = _today()
	if not (item.is_clothing() and item.dirty):
		if not known_gifts.has(npc_id):
			known_gifts[npc_id] = {}
		known_gifts[npc_id][item.id] = [taste, item.display_name]
	var change := change_points(npc_id, GIFT_POINTS[taste])
	var lines: Array = GIFT_LINES[taste]
	_dialogue_box.show_line(npc_name, lines[randi() % lines.size()], change)
	return {"given": true, "change": change, "taste": taste}


## The item names the player knows the NPC feels `taste` about, in the order
## she found them out.
func known_with_taste(npc_id: String, taste: String) -> PackedStringArray:
	var names := PackedStringArray()
	for entry: Array in known_gifts.get(npc_id, {}).values():
		if entry[0] == taste:
			names.append(entry[1])
	return names


func _today() -> int:
	return GameClock.day_index()
