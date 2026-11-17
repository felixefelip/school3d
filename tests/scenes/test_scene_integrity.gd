extends GdUnitTestSuite
## Checks the scenes without running them: every NodePath set on a script
## points at a node that exists, and every door that changes scene leads to
## a scene and spawn point that exist, with a door back.

const SCENES := [
	"res://scenes/main.tscn",
	"res://scenes/house.tscn",
	"res://scenes/street.tscn",
	"res://scenes/cafe.tscn",
]
const SCENE_DOOR := "res://scripts/scene_door.gd"


## Scenes instantiated by the running test, freed before it ends. They are
## added to the tree because some UI scripts create their child nodes in
## variable initializers and only add them in _ready(); outside the tree
## those nodes would be reported as orphans.
var _instances: Array[Node] = []


func _instantiate(path: String) -> Node:
	var root := (load(path) as PackedScene).instantiate()
	_instances.append(root)
	add_child(root)
	return root


func _free_instances() -> void:
	for root in _instances:
		root.free()
	_instances.clear()


func _all_nodes(root: Node) -> Array[Node]:
	var nodes: Array[Node] = [root]
	nodes.append_array(root.find_children("*", "", true, false))
	return nodes


func _scene_doors(root: Node) -> Array[Node]:
	return _all_nodes(root).filter(func(node: Node) -> bool:
		var script: Script = node.get_script()
		return script != null and script.resource_path == SCENE_DOOR)


func test_scenes_load_with_a_player(scene_path: String, test_parameters := [[SCENES[0]], [SCENES[1]], [SCENES[2]], [SCENES[3]]]) -> void:
	var root := _instantiate(scene_path)
	assert_object(root.get_node_or_null("Player")).is_not_null()
	_free_instances()


func test_node_paths_point_at_existing_nodes(scene_path: String, test_parameters := [[SCENES[0]], [SCENES[1]], [SCENES[2]], [SCENES[3]]]) -> void:
	var root := _instantiate(scene_path)
	for node in _all_nodes(root):
		if node.get_script() == null:
			continue
		for property in node.get_property_list():
			if property.type != TYPE_NODE_PATH or not (property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE):
				continue
			var path: NodePath = node.get(property.name)
			if path.is_empty():
				continue
			assert_object(node.get_node_or_null(path)) \
				.override_failure_message("%s: %s.%s = '%s' points at nothing" % [scene_path, root.get_path_to(node), property.name, path]) \
				.is_not_null()
	_free_instances()


func test_scene_doors_lead_to_a_spawn_and_back(scene_path: String, test_parameters := [[SCENES[0]], [SCENES[1]], [SCENES[2]], [SCENES[3]]]) -> void:
	var root := _instantiate(scene_path)
	for door in _scene_doors(root):
		var where := "%s: %s" % [scene_path, root.get_path_to(door)]
		assert_object(door.get_node_or_null(door.door_path)).override_failure_message(where + " has no door mesh").is_not_null()
		assert_bool(ResourceLoader.exists(door.target_scene)) \
			.override_failure_message("%s leads to a missing scene '%s'" % [where, door.target_scene]).is_true()
		var target := _instantiate(door.target_scene)
		assert_object(target.find_child(door.target_spawn, true, false)) \
			.override_failure_message("%s: spawn '%s' is not in %s" % [where, door.target_spawn, door.target_scene]).is_not_null()
		var back := _scene_doors(target).filter(func(d: Node) -> bool: return d.target_scene == scene_path)
		assert_array(back).override_failure_message("%s has no door back to %s" % [door.target_scene, scene_path]).is_not_empty()
	_free_instances()


func test_every_scene_has_a_way_in_or_out() -> void:
	for scene_path in SCENES:
		assert_array(_scene_doors(_instantiate(scene_path))) \
			.override_failure_message(scene_path + " has no door to another scene").is_not_empty()
	_free_instances()
