extends GdUnitTestSuite
## Every item file under res://items/ is filled in and has a unique id.


func _item_paths(dir_path := "res://items") -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(dir_path)
	for sub in dir.get_directories():
		paths.append_array(_item_paths(dir_path.path_join(sub)))
	for file in dir.get_files():
		if file.ends_with(".tres"):
			paths.append(dir_path.path_join(file))
	return paths


func test_there_are_items() -> void:
	assert_int(_item_paths().size()).is_greater(0)


func test_items_are_filled_in() -> void:
	for path in _item_paths():
		var item := load(path) as Item
		assert_object(item).override_failure_message("%s is not an Item" % path).is_not_null()
		assert_str(item.id).override_failure_message("%s has no id" % path).is_not_empty()
		assert_str(item.display_name).override_failure_message("%s has no name" % path).is_not_empty()
		assert_object(item.icon).override_failure_message("%s has no icon" % path).is_not_null()
		assert_bool(item.dirty).override_failure_message("%s starts dirty" % path).is_false()


func test_ids_are_unique() -> void:
	var ids := {}
	for path in _item_paths():
		var item := load(path) as Item
		assert_bool(ids.has(item.id)).override_failure_message("id '%s' is repeated in %s" % [item.id, path]).is_false()
		ids[item.id] = path


func test_clothes_have_a_slot_and_food_does_not() -> void:
	for path in _item_paths("res://items/clothes"):
		assert_bool((load(path) as Item).is_clothing()).override_failure_message(path).is_true()
	for path in _item_paths("res://items/food"):
		assert_bool((load(path) as Item).is_clothing()).override_failure_message(path).is_false()
