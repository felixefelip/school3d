extends GdUnitTestSuite
## The washing machine cleans the clothes inside it and leaves the rest alone.

const WashingMachine := preload("res://scripts/washing_machine.gd")


func _clothing(dirty: bool) -> Item:
	var item := Item.new()
	item.slot = Item.Slot.TOP
	item.dirty = dirty
	item.worn_seconds = 200.0
	return item


func test_wash_cleans_clothes() -> void:
	var machine: Node = auto_free(WashingMachine.new())
	machine.wash_time = 0.05
	machine.slot_count = 4
	add_child(machine)
	var shirt := _clothing(true)
	var apple := Item.new()
	apple.worn_seconds = 5.0
	machine.inventory.items[0] = shirt
	machine.inventory.items[2] = apple
	await machine.perform_action()
	assert_bool(shirt.dirty).is_false()
	assert_float(shirt.worn_seconds).is_equal(0.0)
	assert_float(apple.worn_seconds).is_equal(5.0)
	assert_bool(machine.busy).is_false()


func test_busy_while_washing() -> void:
	var machine: Node = auto_free(WashingMachine.new())
	machine.wash_time = 0.2
	add_child(machine)
	machine.perform_action()
	assert_bool(machine.busy).is_true()
	await await_millis(400)
	assert_bool(machine.busy).is_false()
