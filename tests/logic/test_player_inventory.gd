extends GdUnitTestSuite
## The player's hotbar and outfit (the PlayerInventory autoload). Each test
## uses a fresh instance, so the real autoload is left alone.

const PlayerInventoryScript := preload("res://scripts/inventory/player_inventory.gd")


func _new_player_inventory() -> Node:
	var player_inventory: Node = auto_free(PlayerInventoryScript.new())
	add_child(player_inventory)
	return player_inventory


func test_starts_with_the_school_uniform() -> void:
	var pi := _new_player_inventory()
	var ids: Array = pi.equipment.items.map(func(item: Item) -> String: return item.id if item else "")
	assert_array(ids).contains_exactly(["", "school_shirt", "school_skirt", "school_shoes"])


func test_uniform_pieces_are_copies() -> void:
	var pi := _new_player_inventory()
	var shirt: Item = pi.equipment.items[Outfit.slot_index(Item.Slot.TOP)]
	assert_object(shirt).is_not_same(load("res://items/clothes/school_shirt.tres"))


func test_hotbar_has_ten_empty_slots() -> void:
	var pi := _new_player_inventory()
	assert_int(pi.inventory.size()).is_equal(10)
	assert_int(pi.inventory.items.count(null)).is_equal(10)


func test_selected_wraps_around() -> void:
	var pi := _new_player_inventory()
	pi.selected = 10
	assert_int(pi.selected).is_equal(0)
	pi.selected = -1
	assert_int(pi.selected).is_equal(9)


func test_clothes_get_dirty_after_being_worn_long_enough() -> void:
	var pi := _new_player_inventory()
	pi.set_process(false)
	var shirt: Item = pi.equipment.items[Outfit.slot_index(Item.Slot.TOP)]
	pi._process(PlayerInventoryScript.DIRTY_AFTER - 1.0)
	assert_bool(shirt.dirty).is_false()
	pi._process(1.0)
	assert_bool(shirt.dirty).is_true()


func test_an_empty_slot_does_not_break_the_dirt_timer() -> void:
	var pi := _new_player_inventory()
	pi.set_process(false)
	pi.equipment.items[Outfit.slot_index(Item.Slot.FEET)] = null
	pi._process(PlayerInventoryScript.DIRTY_AFTER)
	assert_bool(pi.equipment.items[Outfit.slot_index(Item.Slot.TOP)].dirty).is_true()
