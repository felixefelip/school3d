extends GdUnitTestSuite
## Runs the scenes for real (physics included) and moves the player around.

const SceneDoor := preload("res://scripts/scene_door.gd")


func _physics_frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame


## Moves the player by hand at a fixed velocity, with gravity, like player.gd does.
func _walk(player: CharacterBody3D, velocity: Vector3, frames: int) -> void:
	for i in frames:
		player.velocity = Vector3(velocity.x, player.velocity.y - 9.8 / 60.0, velocity.z)
		player.move_and_slide()
		await get_tree().physics_frame


func _start(scene_path: String) -> CharacterBody3D:
	var runner := scene_runner(scene_path)
	await _physics_frames(20)
	var player: CharacterBody3D = runner.scene().get_node("Player")
	return player


func test_player_starts_on_the_floor(scene_path: String, test_parameters := [
	["res://scenes/main.tscn"], ["res://scenes/house.tscn"], ["res://scenes/street.tscn"],
	["res://scenes/cafe.tscn"],
]) -> void:
	var player := await _start(scene_path)
	assert_bool(player.is_on_floor()).is_true()
	assert_float(player.global_position.y).is_between(-0.2, 0.2)


## Loading a scene through a door puts the player on that door's spawn point.
func test_arrives_at_the_spawn_point(scene_path: String, spawn: String, test_parameters := [
	["res://scenes/street.tscn", "FromApartment"],
	["res://scenes/street.tscn", "FromSchool"],
	["res://scenes/house.tscn", "FromStreet"],
	["res://scenes/main.tscn", "FromStreet"],
	["res://scenes/street.tscn", "FromCafe"],
	["res://scenes/cafe.tscn", "FromStreet"],
]) -> void:
	SceneDoor._arrival_spawn = spawn
	var runner := scene_runner(scene_path)
	await _physics_frames(20)
	var player: CharacterBody3D = runner.scene().get_node("Player")
	var marker: Node3D = runner.scene().find_child(spawn, true, false)
	var offset := player.global_position - marker.global_position
	offset.y = 0.0
	assert_float(offset.length()).is_less(0.05)
	assert_bool(player.is_on_floor()).is_true()
	assert_str(SceneDoor._arrival_spawn).is_empty()


func test_steps_down_the_curb_and_back_up() -> void:
	var player := await _start("res://scenes/street.tscn")
	player.set_physics_process(false)
	player.global_position = Vector3(42, 0.05, 30)  # new street, west sidewalk
	await _walk(player, Vector3(2, 0, 0), 90)
	assert_float(player.global_position.x).is_greater(44.5)
	assert_float(player.global_position.y).is_equal_approx(-0.15, 0.03)
	await _walk(player, Vector3(-2, 0, 0), 90)
	assert_float(player.global_position.x).is_less(43.0)
	assert_float(player.global_position.y).is_equal_approx(0.0, 0.03)


func test_school_fence_and_street_ends_block_the_way() -> void:
	var player := await _start("res://scenes/street.tscn")
	player.set_physics_process(false)
	player.global_position = Vector3(55, 0.05, 70)
	await _walk(player, Vector3(3, 0, 0), 60)
	assert_float(player.global_position.x).is_less(56.0)
	player.global_position = Vector3(48, 0.05, 95)
	await _walk(player, Vector3(0, 0, 3), 180)
	assert_float(player.global_position.z).is_less(100.2)
	player.global_position = Vector3(-35, 0.05, 8)
	await _walk(player, Vector3(-3, 0, 0), 180)
	assert_float(player.global_position.x).is_greater(-40.2)


func test_walks_and_runs_at_the_configured_speeds() -> void:
	var runner := scene_runner("res://scenes/street.tscn")
	await _physics_frames(20)
	var player: CharacterBody3D = runner.scene().get_node("Player")
	runner.simulate_key_press(KEY_W)
	await _physics_frames(10)
	var walk := Vector2(player.velocity.x, player.velocity.z).length()
	assert_float(walk).is_equal_approx(player.speed * player.walk_multiplier, 0.01)
	runner.simulate_key_press(KEY_SHIFT)
	await _physics_frames(10)
	var run := Vector2(player.velocity.x, player.velocity.z).length()
	assert_float(run).is_equal_approx(player.speed * player.run_multiplier, 0.01)
	runner.simulate_key_release(KEY_SHIFT)
	runner.simulate_key_release(KEY_W)


func test_orders_a_coffee_at_the_cafe_counter() -> void:
	var runner := scene_runner("res://scenes/cafe.tscn")
	await _physics_frames(10)
	var counter: Node = runner.scene().get_node("CoffeeCounter")
	var hotbar: Inventory = PlayerInventory.inventory
	var before := hotbar.items.duplicate()
	assert_str(counter.get_prompt()).is_equal("Order a coffee")
	counter.interact(runner.scene().get_node("Player"))
	var slot := before.find(null)
	var cup: Item = hotbar.items[slot]
	assert_object(cup).is_not_null()
	assert_str(cup.id).is_equal("coffee")
	assert_object(cup).is_not_same(counter.item)
	hotbar.items[slot] = null  # leave the real autoload as it was


func test_cafe_has_free_chairs_to_sit_on() -> void:
	var runner := scene_runner("res://scenes/cafe.tscn")
	await _physics_frames(10)
	var seats := runner.scene().get_children().filter(func(n: Node) -> bool: return n.name.begins_with("CafeChair"))
	assert_int(seats.size()).is_greater(5)
	for seat: Node in seats:
		assert_bool(seat.chair.has_meta("occupied")).is_false()


func test_bia_and_lucas_can_be_talked_to_in_the_cafe() -> void:
	var runner := scene_runner("res://scenes/cafe.tscn")
	await _physics_frames(10)
	var bia: Node = runner.scene().get_node("Customers/CustomerWindow")
	var lucas: Node = runner.scene().get_node("Customers/CustomerLongTable")
	assert_str(bia.get_prompt()).is_equal("Talk to Bia")
	assert_str(lucas.get_prompt()).is_equal("Talk to Lucas")
	assert_bool(bia.is_in_group("interactable")).is_true()
	# The other customers are just background students.
	assert_bool(runner.scene().get_node("Customers/CustomerLongTable2").is_in_group("interactable")).is_false()
	var points_before: int = Relationships.get_points("bia")
	var cooldown_before: float = Relationships.talk_cooldown
	Relationships.talk_cooldown = 0.0
	bia.interact(runner.scene().get_node("Player"))
	var expected := 1 if Relationships.is_outfit_clean() else maxi(points_before - 1, 0) - points_before
	assert_int(Relationships.get_points("bia") - points_before).is_equal(expected)
	Relationships.points["bia"] = points_before
	Relationships.talk_cooldown = cooldown_before
