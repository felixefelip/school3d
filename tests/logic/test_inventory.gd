extends GdUnitTestSuite
## Inventory: a fixed number of slots, filled in order and swapped by move().


func _item(item_name: String) -> Item:
	var item := Item.new()
	item.id = item_name
	return item


func test_create_has_empty_slots() -> void:
	var inv := Inventory.create(4)
	assert_int(inv.size()).is_equal(4)
	assert_array(inv.items).contains_exactly([null, null, null, null])


func test_add_fills_the_first_empty_slot() -> void:
	var inv := Inventory.create(3)
	var apple := _item("apple")
	var milk := _item("milk")
	inv.items[0] = _item("cap")
	assert_bool(inv.add(apple)).is_true()
	assert_bool(inv.add(milk)).is_true()
	assert_object(inv.items[1]).is_same(apple)
	assert_object(inv.items[2]).is_same(milk)


func test_add_fails_when_full() -> void:
	var inv := Inventory.create(1)
	assert_bool(inv.add(_item("apple"))).is_true()
	var changes := [0]
	inv.changed.connect(func() -> void: changes[0] += 1)
	assert_bool(inv.add(_item("milk"))).is_false()
	assert_int(changes[0]).is_equal(0)


func test_add_emits_changed() -> void:
	var inv := Inventory.create(2)
	var changes := [0]
	inv.changed.connect(func() -> void: changes[0] += 1)
	inv.add(_item("apple"))
	assert_int(changes[0]).is_equal(1)


func test_move_swaps_within_one_inventory() -> void:
	var inv := Inventory.create(3)
	var apple := _item("apple")
	var milk := _item("milk")
	inv.items[0] = apple
	inv.items[2] = milk
	Inventory.move(inv, 0, inv, 2)
	assert_object(inv.items[0]).is_same(milk)
	assert_object(inv.items[2]).is_same(apple)


func test_move_into_an_empty_slot_of_another_inventory() -> void:
	var hotbar := Inventory.create(2)
	var fridge := Inventory.create(2)
	var milk := _item("milk")
	fridge.items[1] = milk
	var hotbar_changes := [0]
	var fridge_changes := [0]
	hotbar.changed.connect(func() -> void: hotbar_changes[0] += 1)
	fridge.changed.connect(func() -> void: fridge_changes[0] += 1)
	Inventory.move(fridge, 1, hotbar, 0)
	assert_object(hotbar.items[0]).is_same(milk)
	assert_object(fridge.items[1]).is_null()
	assert_int(hotbar_changes[0]).is_equal(1)
	assert_int(fridge_changes[0]).is_equal(1)


func test_move_to_the_same_slot_does_nothing() -> void:
	var inv := Inventory.create(2)
	var apple := _item("apple")
	inv.items[0] = apple
	var changes := [0]
	inv.changed.connect(func() -> void: changes[0] += 1)
	Inventory.move(inv, 0, inv, 0)
	assert_object(inv.items[0]).is_same(apple)
	assert_int(changes[0]).is_equal(0)
