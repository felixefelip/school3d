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
	rel.register("ana", "Ana", "School")
	assert_array(rel.list_people()).contains(["ana"])
	assert_str(rel.people["ana"].name).is_equal("Ana")


func test_talking_marks_as_met() -> void:
	var rel := _new_relationships()
	assert_bool(rel.met.has("bia")).is_false()
	rel.talk("bia", "Bia", NICE, RUDE)
	assert_bool(rel.met.has("bia")).is_true()
