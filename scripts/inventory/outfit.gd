class_name Outfit
extends RefCounted
## Dresses a student model (player or preview) in the clothes of an equipment
## inventory, one slot per Item.Slot (HEAD, TOP, LEGS, FEET, in that order).
##  - Top: tints the shirt in the item's color and hides the uniform's bow.
##  - Legs: the jeans (skinned on the same skeleton) replace the skirt.
##  - Feet: paints the shoes in the item's color.
##  - Head: the cap, attached to the head bone.

const JEANS := preload("res://models/clothes/jeans.glb")
const CAP := preload("res://models/clothes/cap.tscn")
## Marks the nodes added here, so the next apply() can remove them.
const ADDED := "outfit_piece"


static func slot_index(slot: Item.Slot) -> int:
	return slot - 1


static func apply(model: Node3D, equipment: Inventory) -> void:
	var skeleton: Skeleton3D = model.get_node("Skeleton3D")
	for child in skeleton.get_children():
		if child.has_meta(ADDED):
			child.free()
	var head := equipment.items[slot_index(Item.Slot.HEAD)]
	var top := equipment.items[slot_index(Item.Slot.TOP)]
	var legs := equipment.items[slot_index(Item.Slot.LEGS)]
	var feet := equipment.items[slot_index(Item.Slot.FEET)]

	_paint(skeleton.get_node("Shirt"), top, true)
	skeleton.get_node("Bow").visible = top == null
	_paint(skeleton.get_node("Shoes"), feet, false)

	skeleton.get_node("Skirt").visible = legs == null
	if legs:
		var jeans := JEANS.instantiate()
		for source: MeshInstance3D in jeans.find_children("*", "MeshInstance3D", true, false):
			var piece := MeshInstance3D.new()
			piece.mesh = source.mesh
			piece.skin = source.skin
			piece.set_meta(ADDED, true)
			skeleton.add_child(piece)
			piece.skeleton = NodePath("..")
		jeans.free()
		StudentAnimations.use_vertex_colors(skeleton)

	if head:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = "Head"
		attachment.set_meta(ADDED, true)
		skeleton.add_child(attachment)
		attachment.add_child(CAP.instantiate())


## Tints a mesh in the item's color, or restores it when there's no item.
## The shirt is near white, so multiplying keeps its seams and shading; the
## shoes are dark brown and get a plain color instead.
static func _paint(mesh_instance: MeshInstance3D, item: Item, keep_shading: bool) -> void:
	if item == null:
		mesh_instance.material_override = null
		return
	var material := (mesh_instance.mesh.surface_get_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	material.vertex_color_use_as_albedo = keep_shading
	material.albedo_color = item.color
	mesh_instance.material_override = material
