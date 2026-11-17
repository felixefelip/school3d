extends GdUnitTestSuite
## Giving a gift in the café: with an item selected in the hotbar, the prompt
## next to Bia offers [G] and G hands the item over.


func test_give_bia_a_coffee() -> void:
	var runner := scene_runner("res://scenes/cafe.tscn")
	for i in 10:
		await get_tree().physics_frame
	var scene := runner.scene()
	var player: Node3D = scene.get_node("Player")
	var bia: Node3D = scene.get_node("Customers/CustomerWindow")
	var saved_points: Dictionary = Relationships.points.duplicate()
	var saved_gifts: Dictionary = Relationships._last_gift.duplicate()
	var saved_known: Dictionary = Relationships.known_gifts.duplicate(true)
	var saved_slot: Item = PlayerInventory.inventory.items[0]
	Relationships.points["bia"] = 0
	Relationships._last_gift.erase("bia")
	PlayerInventory.inventory.items[0] = (load("res://items/food/coffee.tres") as Item).duplicate()
	PlayerInventory.selected = 0

	player.global_position = bia.get_interaction_point() + Vector3(0, 0.05, 0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var prompt: Label = player.get_node("HUD/Prompt")
	assert_str(prompt.text).contains("[G] Give Coffee")
	runner.simulate_key_pressed(KEY_G)
	await get_tree().process_frame
	assert_int(Relationships.get_points("bia")).is_equal(3)
	assert_object(PlayerInventory.inventory.items[0]).is_null()
	assert_array(Relationships.known_with_taste("bia", "loved")).contains(["Coffee"])

	PlayerInventory.inventory.items[0] = saved_slot
	PlayerInventory.inventory.emit_changed()
	Relationships.points = saved_points
	Relationships._last_gift = saved_gifts
	Relationships.known_gifts = saved_known
