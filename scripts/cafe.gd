extends Node3D
## Inside Cafe Aroma. The room (Interior) is built in the café building's own
## space and placed where the building stands in the city (City, the same
## scenes/city.tscn as the street), so the street shows through the windows.
##
## On startup it opens the café's block in the city (the room would be inside
## a solid box otherwise), builds collision for the room and its furniture
## and makes the free chairs sittable.

const Seat := preload("res://scripts/seat.gd")

## Meshes too small to bump into, high up or flat on the floor/walls.
const NO_COLLISION := [
	"FloorBoard", "CeilingBeam", "Wainscot", "WindowSill", "DoorFrame", "Handle", "Pendant",
	"Cake", "Croissant", "Register", "Espresso", "Cup", "Grinder", "Jar", "CoffeeBag", "Shelf",
	"Menu", "Rug", "Book", "Laptop", "FloorLamp", "Restroom", "Sign", "Picture", "Neon", "Clock",
	"Display",
]

@export var city_path: NodePath = ^"City"
@export var interior_path: NodePath = ^"Interior"

## The café building in the city, and the top of the room (its ceiling) in
## the building's space.
const BUILDING := "Buildings/Cafe"
const ROOM_TOP := 3.9


func _ready() -> void:
	_open_building()
	var interior := get_node(interior_path)
	for mesh_instance: MeshInstance3D in interior.find_children("*", "MeshInstance3D", true, false):
		if not _skip(mesh_instance.name):
			mesh_instance.create_convex_collision(true, false)
	for chair: Node3D in interior.find_children("CafeChair*", "Node3D", true, false):
		if chair.has_meta("occupied"):
			continue
		var seat := Seat.new()
		seat.name = String(chair.name) + "Seat"
		add_child(seat)
		seat.setup(chair)


func _skip(mesh_name: String) -> bool:
	for prefix in NO_COLLISION:
		if mesh_name.begins_with(prefix):
			return true
	return false


## Hides the building's solid block, dark shop windows and door, and puts the
## block back only above the room, so the floors above still cast shadows.
func _open_building() -> void:
	var building: Node3D = get_node(city_path).get_node(BUILDING)
	var wall: MeshInstance3D = building.get_node("Wall")
	var block := wall.mesh as BoxMesh
	wall.visible = false
	for child in building.get_children():
		var child_name := String(child.name)
		var is_shop_glass := child_name.begins_with("WindowShop") and not child_name.begins_with("WindowShopFrame")
		if is_shop_glass or child_name.begins_with("ShopDoor") or child_name.begins_with("HandleShop"):
			child.visible = false
	var above := BoxMesh.new()
	above.size = Vector3(block.size.x, block.size.y - ROOM_TOP, block.size.z)
	above.material = block.material
	var piece := MeshInstance3D.new()
	piece.name = "WallAboveCafe"
	piece.mesh = above
	piece.position = Vector3(wall.position.x, ROOM_TOP + above.size.y / 2, wall.position.z)
	building.add_child(piece)
