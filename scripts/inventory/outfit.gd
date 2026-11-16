class_name Outfit
extends RefCounted
## Dresses a student model (player or preview) in the clothes of an equipment
## inventory, one slot per Item.Slot (HEAD, TOP, LEGS, FEET, in that order).
## Each slot shows, by the worn item (see Item):
##  - keep_original: the model's own piece (the school uniform).
##  - model_scene: an extra model (jeans on the skeleton, cap on the head).
##  - otherwise: the model's own piece painted in the item's color.
## An empty slot shows the underwear: a white top, white shorts, bare feet.
## The model's body ends at the ankles (the feet are inside the shoes), so
## bare feet are a model of their own.

const UNDERWEAR_TOP := preload("res://models/clothes/top.glb")
const UNDERWEAR_SHORTS := preload("res://models/clothes/shorts.glb")
const BARE_FEET := preload("res://models/clothes/bare_feet.glb")
## Marks the nodes added here, so the next apply() can remove them.
const ADDED := "outfit_piece"


static func slot_index(slot: Item.Slot) -> int:
	return slot - 1


static func apply(model: Node3D, equipment: Inventory) -> void:
	var skeleton: Skeleton3D = model.get_node("Skeleton3D")
	for child in skeleton.get_children():
		if child.has_meta(ADDED):
			child.free()
	var shirt: MeshInstance3D = skeleton.get_node("Shirt")
	var bow: MeshInstance3D = skeleton.get_node("Bow")
	var skirt: MeshInstance3D = skeleton.get_node("Skirt")
	var shoes: MeshInstance3D = skeleton.get_node("Shoes")
	var socks: MeshInstance3D = skeleton.get_node("Socks")

	_wear(skeleton, equipment.items[slot_index(Item.Slot.TOP)], [shirt, bow], shirt, true, UNDERWEAR_TOP)
	_wear(skeleton, equipment.items[slot_index(Item.Slot.LEGS)], [skirt], skirt, true, UNDERWEAR_SHORTS)
	var feet := equipment.items[slot_index(Item.Slot.FEET)]
	_wear(skeleton, feet, [shoes, socks], shoes, false, BARE_FEET)
	# Sneakers are worn over the uniform's socks.
	socks.visible = feet != null

	var head := equipment.items[slot_index(Item.Slot.HEAD)]
	if head and head.model_scene:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = "Head"
		attachment.set_meta(ADDED, true)
		skeleton.add_child(attachment)
		attachment.add_child(head.model_scene.instantiate())

	StudentAnimations.use_vertex_colors(skeleton)


## Shows `item` on one slot of the body. `own` are the model's meshes for that
## slot; `paintable` is the one painted in the item's color.
static func _wear(skeleton: Skeleton3D, item: Item, own: Array, paintable: MeshInstance3D,
		keep_shading: bool, underwear: PackedScene) -> void:
	for mesh_instance: MeshInstance3D in own:
		mesh_instance.visible = item != null and (item.keep_original or item.model_scene == null)
		mesh_instance.material_override = null
	if item == null:
		if underwear:
			_add_skinned(skeleton, underwear)
	elif item.model_scene:
		_add_skinned(skeleton, item.model_scene)
	elif not item.keep_original:
		for mesh_instance: MeshInstance3D in own:
			mesh_instance.visible = mesh_instance == paintable
		_paint(paintable, item.color, keep_shading)


## Adds the skinned meshes of a clothing model (made on the same skeleton) to
## the character's skeleton, so they follow her animations.
static func _add_skinned(skeleton: Skeleton3D, scene: PackedScene) -> void:
	var source_root := scene.instantiate()
	for source: MeshInstance3D in source_root.find_children("*", "MeshInstance3D", true, false):
		var piece := MeshInstance3D.new()
		piece.mesh = source.mesh
		piece.skin = source.skin
		piece.set_meta(ADDED, true)
		skeleton.add_child(piece)
		piece.skeleton = NodePath("..")
	source_root.free()


## The shirt is near white, so multiplying keeps its seams and shading; the
## shoes are dark brown and get a plain color instead.
static func _paint(mesh_instance: MeshInstance3D, color: Color, keep_shading: bool) -> void:
	var material := (mesh_instance.mesh.surface_get_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	material.vertex_color_use_as_albedo = keep_shading
	material.albedo_color = color
	mesh_instance.material_override = material
