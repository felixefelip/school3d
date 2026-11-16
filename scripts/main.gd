extends Node3D
## Builds collision for the level on startup so the player can't walk through
## walls, furniture or the floor. The glTF model has no collision of its own.
##
## Floors become a flat box: their mesh has thousands of triangles (the floor
## boards) and a collision copied from it pushes the character around.
## Walls with an opening get an exact (trimesh) collision, because a convex
## hull would fill the opening. Everything else gets a convex hull, which is
## lighter than copying every triangle.

const LEVEL := ["School", "ClassroomBackWall", "ClassroomDecor", "Ceiling"]
## Floor meshes inside the school model: Floor, FloorHallway, FloorCafeteria.
const FLOOR_PREFIX := "Floor"
## Walls with a door opening.
const EXACT_COLLISION := ["WallDoor", "ClassroomWallTrim"]


func _ready() -> void:
	for node_name in LEVEL:
		var node := get_node(node_name)
		var meshes := node.find_children("*", "MeshInstance3D", true, false)
		if node is MeshInstance3D:
			meshes.append(node)
		for mesh_instance: MeshInstance3D in meshes:
			if mesh_instance.name.begins_with(FLOOR_PREFIX):
				_create_box(mesh_instance)
			elif mesh_instance.name in EXACT_COLLISION:
				mesh_instance.create_trimesh_collision()
			else:
				mesh_instance.create_convex_collision(true, false)


func _create_box(mesh_instance: MeshInstance3D) -> void:
	var bounds := mesh_instance.global_transform * mesh_instance.get_aabb()
	var shape := BoxShape3D.new()
	shape.size = bounds.size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var body := StaticBody3D.new()
	body.name = mesh_instance.name + "_col"
	body.add_child(collision)
	add_child(body)
	body.global_position = bounds.get_center()
