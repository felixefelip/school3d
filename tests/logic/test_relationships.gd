extends GdUnitTestSuite
## Friendship points: clean clothes +1, dirty clothes -1, never below zero,
## and at most one change per NPC per day. Each test uses
## a fresh Relationships; the player's clothes (the real PlayerInventory) are
## put back as they were.

const RelationshipsScript := preload("res://scripts/relationships.gd")
const NICE := ["Hi!"]
const RUDE := ["Ew."]

var _dirty_before: Array = []


func before_test() -> void:
	_dirty_before = PlayerInventory.equipment.items.map(func(item: Item) -> bool: return item != null and item.dirty)


func after_test() -> void:
	for i in PlayerInventory.equipment.items.size():
		var item: Item = PlayerInventory.equipment.items[i]
		if item:
			item.dirty = _dirty_before[i]


func _new_relationships() -> Node:
	var relationships: Node = auto_free(RelationshipsScript.new())
	add_child(relationships)
	return relationships


func _set_outfit_dirty(dirty: bool) -> void:
	for item: Item in PlayerInventory.equipment.items:
		if item:
			item.dirty = dirty


func test_starts_at_zero() -> void:
	assert_int(_new_relationships().get_points("bia")).is_equal(0)


func test_clean_clothes_gain_a_point() -> void:
	var rel := _new_relationships()
	_set_outfit_dirty(false)
	assert_bool(rel.is_outfit_clean()).is_true()
	assert_int(rel.talk("bia", "Bia", NICE, RUDE)).is_equal(1)
	assert_int(rel.get_points("bia")).is_equal(1)


func test_dirty_clothes_lose_a_point() -> void:
	var rel := _new_relationships()
	rel.points["bia"] = 3
	_set_outfit_dirty(false)
	PlayerInventory.equipment.items[Outfit.slot_index(Item.Slot.FEET)].dirty = true
	assert_bool(rel.is_outfit_clean()).is_false()
	assert_int(rel.talk("bia", "Bia", NICE, RUDE)).is_equal(-1)
	assert_int(rel.get_points("bia")).is_equal(2)


func test_points_do_not_go_below_zero() -> void:
	var rel := _new_relationships()
	_set_outfit_dirty(true)
	assert_int(rel.talk("bia", "Bia", NICE, RUDE)).is_equal(0)
	assert_int(rel.get_points("bia")).is_equal(0)


func test_talking_again_the_same_day_does_not_change_points() -> void:
	var rel := _new_relationships()
	_set_outfit_dirty(false)
	rel.talk("bia", "Bia", NICE, RUDE)
	assert_int(rel.talk("bia", "Bia", NICE, RUDE)).is_equal(0)
	assert_int(rel.get_points("bia")).is_equal(1)
	# Each NPC has its own cooldown.
	assert_int(rel.talk("lucas", "Lucas", NICE, RUDE)).is_equal(1)
	# The next day it counts again.
	GameClock.day += 1
	assert_int(rel.talk("bia", "Bia", NICE, RUDE)).is_equal(1)
	GameClock.day -= 1
	assert_int(rel.get_points("bia")).is_equal(2)


func test_empty_slots_count_as_clean() -> void:
	var rel := _new_relationships()
	_set_outfit_dirty(false)
	var head := Outfit.slot_index(Item.Slot.HEAD)
	assert_object(PlayerInventory.equipment.items[head]).is_null()
	assert_bool(rel.is_outfit_clean()).is_true()


func test_changed_is_emitted() -> void:
	var rel := _new_relationships()
	_set_outfit_dirty(false)
	var got := []
	rel.changed.connect(func(npc_id: String, points: int) -> void: got.append([npc_id, points]))
	rel.talk("lucas", "Lucas", NICE, RUDE)
	assert_array(got).contains_exactly([["lucas", 1]])


func test_level_names() -> void:
	assert_str(RelationshipsScript.level_name(0)).is_equal("Stranger")
	assert_str(RelationshipsScript.level_name(2)).is_equal("Acquaintance")
	assert_str(RelationshipsScript.level_name(3)).is_equal("Friend")
	assert_str(RelationshipsScript.level_name(7)).is_equal("Good friend")
	assert_str(RelationshipsScript.level_name(25)).is_equal("Best friend")


func test_lists_everyone_and_registers_newcomers() -> void:
	var rel := _new_relationships()
	assert_array(rel.list_people()).contains(["bia", "lucas"])
	for npc_id in ["bia", "lucas"]:
		assert_bool(ResourceLoader.exists(rel.people[npc_id].model)).override_failure_message(npc_id + " has no model").is_true()
	rel.register("ana", "Ana", "School")
	assert_array(rel.list_people()).contains(["ana"])
	assert_str(rel.people["ana"].name).is_equal("Ana")


func test_talking_marks_as_met() -> void:
	var rel := _new_relationships()
	assert_bool(rel.met.has("bia")).is_false()
	rel.talk("bia", "Bia", NICE, RUDE)
	assert_bool(rel.met.has("bia")).is_true()


func test_says_one_thing_per_day() -> void:
	var rel := _new_relationships()
	_set_outfit_dirty(false)
	var many := ["One", "Two", "Three", "Four", "Five", "Six"]
	rel.talk("bia", "Bia", many, RUDE)
	var first: String = rel.todays_line("bia")
	assert_array(many).contains([first])
	for i in 10:
		rel.talk("bia", "Bia", many, RUDE)
		assert_str(rel.todays_line("bia")).is_equal(first)
	# Even if her clothes get dirty later that day, the line (and the points) stay.
	_set_outfit_dirty(true)
	assert_int(rel.talk("bia", "Bia", many, RUDE)).is_equal(0)
	assert_str(rel.todays_line("bia")).is_equal(first)
	assert_int(rel.get_points("bia")).is_equal(1)


func test_a_new_day_brings_a_new_line_and_point() -> void:
	var rel := _new_relationships()
	_set_outfit_dirty(false)
	rel.talk("bia", "Bia", NICE, RUDE)
	GameClock.day += 1
	assert_str(rel.todays_line("bia")).is_empty()
	_set_outfit_dirty(true)
	rel.points["bia"] = 2
	assert_int(rel.talk("bia", "Bia", NICE, RUDE)).is_equal(-1)
	assert_str(rel.todays_line("bia")).is_equal("Ew.")
	GameClock.day -= 1


func _item(path: String) -> Item:
	return (load(path) as Item).duplicate()


func test_gift_tastes() -> void:
	var rel := _new_relationships()
	assert_str(rel.gift_taste("bia", _item("res://items/food/coffee.tres"))).is_equal("loved")
	assert_str(rel.gift_taste("bia", _item("res://items/food/apple.tres"))).is_equal("liked")
	assert_str(rel.gift_taste("bia", _item("res://items/food/orange.tres"))).is_equal("neutral")
	assert_str(rel.gift_taste("bia", _item("res://items/food/milk.tres"))).is_equal("disliked")
	assert_str(rel.gift_taste("bia", _item("res://items/food/cheese.tres"))).is_equal("hated")
	assert_str(rel.gift_taste("lucas", _item("res://items/food/cheese.tres"))).is_equal("liked")
	# Someone without tastes takes anything as neutral; dirty clothes are hated by all.
	assert_str(rel.gift_taste("nobody", _item("res://items/food/coffee.tres"))).is_equal("neutral")
	var dirty_cap := _item("res://items/clothes/cap.tres")
	dirty_cap.dirty = true
	assert_str(rel.gift_taste("bia", dirty_cap)).is_equal("hated")


func test_every_gift_taste_is_a_real_item() -> void:
	var ids := []
	for folder in ["res://items/food/", "res://items/clothes/"]:
		for file in DirAccess.get_files_at(folder):
			if file.ends_with(".tres"):
				ids.append((load(folder + file) as Item).id)
	for npc_id: String in RelationshipsScript.PEOPLE:
		for taste in ["loved", "liked", "disliked", "hated"]:
			for item_id: String in RelationshipsScript.PEOPLE[npc_id][taste]:
				assert_array(ids).override_failure_message("%s: unknown item %s" % [npc_id, item_id]).contains([item_id])


func test_gifts_change_points_by_taste_once_a_day() -> void:
	var rel := _new_relationships()
	var result: Dictionary = rel.give("bia", "Bia", _item("res://items/food/coffee.tres"))
	assert_bool(result.given).is_true()
	assert_int(result.change).is_equal(3)
	assert_int(rel.get_points("bia")).is_equal(3)
	assert_bool(rel.met.has("bia")).is_true()
	# A second gift the same day isn't taken.
	assert_bool(rel.can_gift("bia")).is_false()
	result = rel.give("bia", "Bia", _item("res://items/food/coffee.tres"))
	assert_bool(result.given).is_false()
	assert_int(rel.get_points("bia")).is_equal(3)
	# Lucas has his own limit, and a hated gift costs points.
	assert_int(rel.give("lucas", "Lucas", _item("res://items/food/orange_juice.tres")).change).is_equal(0)
	rel.points["lucas"] = 5
	GameClock.day += 1
	assert_int(rel.give("lucas", "Lucas", _item("res://items/food/orange_juice.tres")).change).is_equal(-2)
	assert_int(rel.give("bia", "Bia", _item("res://items/food/orange.tres")).change).is_equal(1)
	GameClock.day -= 1
	assert_int(rel.get_points("lucas")).is_equal(3)


func test_gift_and_talk_have_separate_limits() -> void:
	var rel := _new_relationships()
	_set_outfit_dirty(false)
	rel.give("bia", "Bia", _item("res://items/food/apple.tres"))
	assert_int(rel.talk("bia", "Bia", NICE, RUDE)).is_equal(1)
	assert_int(rel.get_points("bia")).is_equal(3)


func test_gifts_reveal_tastes() -> void:
	var rel := _new_relationships()
	assert_array(rel.known_with_taste("bia", "loved")).is_empty()
	rel.give("bia", "Bia", _item("res://items/food/coffee.tres"))
	GameClock.day += 1
	rel.give("bia", "Bia", _item("res://items/food/cheese.tres"))
	GameClock.day -= 1
	assert_array(rel.known_with_taste("bia", "loved")).contains_exactly(["Coffee"])
	assert_array(rel.known_with_taste("bia", "hated")).contains_exactly(["Cheese"])
	assert_array(rel.known_with_taste("bia", "liked")).is_empty()
