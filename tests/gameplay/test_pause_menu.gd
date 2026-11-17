extends GdUnitTestSuite
## The pause menu (Esc) and the relationships list it opens.


func after_test() -> void:
	get_tree().paused = false


func _start() -> Array:
	var runner := scene_runner("res://scenes/street.tscn")
	for i in 10:
		await get_tree().physics_frame
	var player: Node = runner.scene().get_node("Player")
	return [runner, player, player.get_node("HUD/PauseMenu"), player.get_node("HUD/RelationshipsWindow")]


func test_esc_pauses_and_resume_goes_back() -> void:
	var parts: Array = await _start()
	var runner: GdUnitSceneRunner = parts[0]
	var menu: Control = parts[2]
	runner.simulate_key_pressed(KEY_ESCAPE)
	await get_tree().process_frame
	assert_bool(menu.visible).is_true()
	assert_bool(get_tree().paused).is_true()
	menu.find_child("Resume", true, false).pressed.emit()
	assert_bool(menu.visible).is_false()
	assert_bool(get_tree().paused).is_false()


func test_outfit_button_opens_the_outfit_menu() -> void:
	var parts: Array = await _start()
	var player: Node = parts[1]
	var menu: Control = parts[2]
	player.open_pause_menu()
	menu.find_child("Outfit", true, false).pressed.emit()
	assert_bool(get_tree().paused).is_false()
	assert_bool(player.get_node("HUD/OutfitWindow").visible).is_true()
	player.close_menu()


func test_relationships_lists_people_with_points() -> void:
	var parts: Array = await _start()
	var player: Node = parts[1]
	var menu: Control = parts[2]
	var window: Control = parts[3]
	var saved_points: Dictionary = Relationships.points.duplicate()
	var saved_met: Dictionary = Relationships.met.duplicate()
	var saved_known: Dictionary = Relationships.known_gifts.duplicate(true)
	Relationships.known_gifts = {"bia": {"coffee": ["loved", "Coffee"], "cheese": ["hated", "Cheese"]}}
	Relationships.points["bia"] = 4
	Relationships.met["bia"] = true
	Relationships.points.erase("lucas")
	Relationships.met.erase("lucas")

	player.open_pause_menu()
	menu.find_child("Relationships", true, false).pressed.emit()
	assert_bool(window.visible).is_true()
	var bia: Control = window.find_child("bia", true, false)
	assert_str((bia.find_child("Name", true, false) as Label).text).is_equal("Bia")
	assert_str((bia.find_child("Details", true, false) as Label).text).starts_with("Friend")
	assert_str((bia.find_child("Points", true, false) as Label).text).is_equal("4 points")
	assert_int(bia.find_child("Hearts", true, false).filled).is_equal(4)
	assert_str((bia.find_child("Gifts", true, false) as Label).text).is_equal("Loves: Coffee  ·  Hates: Cheese")
	assert_object(bia.find_child("Portrait", true, false)).is_not_null()
	assert_object(bia.find_child("Portrait", true, false).find_child("*", true, false)).is_not_null()
	var lucas: Control = window.find_child("lucas", true, false)
	assert_str((lucas.find_child("Details", true, false) as Label).text).starts_with("Not met yet")
	assert_int(lucas.find_child("Hearts", true, false).filled).is_equal(0)
	assert_bool((lucas.find_child("Gifts", true, false) as Label).visible).is_false()

	# Back returns to the pause menu, which is still paused.
	window.find_child("Back", true, false).pressed.emit()
	assert_bool(window.visible).is_false()
	assert_bool(menu.visible).is_true()
	assert_bool(get_tree().paused).is_true()
	menu.resume()
	Relationships.points = saved_points
	Relationships.met = saved_met
	Relationships.known_gifts = saved_known
