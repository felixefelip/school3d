extends Node3D
## The player's apartment (one floor). Builds collision for the rooms and
## furniture on startup (they are simple shapes, so a convex hull per mesh is
## exact enough) and makes the desk chair sittable.
##
## The view from the windows is the same neighbourhood as the street scene
## (scenes/city.tscn, instanced as City): the apartment is on the 5th floor of
## Residencial Aurora, with the balcony on the building's street front. City
## is placed so that its origin is where the street scene's origin would be.

const Seat := preload("res://scripts/seat.gd")

const LEVEL := [
	"Bedroom", "Hallway", "Bathroom", "ParentsRoom", "Kitchen", "LivingRoom",
	"Balcony", "ServiceArea", "Apartment",
]
## Meshes flat on the floor or too small to bump into.
const NO_COLLISION := [
	"Rug", "Runner", "Laptop", "Mug", "Book", "Lamp", "CeilingLight", "StairLight", "Handle",
	"Step", "Threshold", "Picture", "Frame", "Baseboard", "Window", "Border",
	"ShowerTray", "ShowerPipe", "ShowerArm", "ShowerHead", "ShowerValve", "Faucet", "Toothbrushes", "Soap",
	"Mirror", "Towel", "ToiletPaper", "WallNorthTiles", "Washer", "Detergent",
	"AC", "AirConditioner", "GuitarSoundHole", "GuitarBridge", "GuitarFretboard", "GuitarNut",
	"GuitarHead", "GuitarTuner", "GuitarStrings",
	"Burner", "Cooktop", "SinkBasin", "KitchenFaucet", "CabinetDoorLine", "OvenHandle", "OvenDoor",
	"FridgeDoorLine", "FridgeHandle", "FridgeMagnet", "Fruit", "Remote", "TvScreen", "SofaPillow",
	"DoorMat", "Perfume", "Jewelry", "DresserDrawerLine", "DresserMirror", "LaundryTubBasin",
	"LaundryTubFaucet", "Clothesline", "HangingTowel", "Broom", "CleaningBottle", "BalconyMug",
	"BuildingRoof",
	"CoffeeMaker", "SideboardDoorLine", "SideboardTop", "MicrowaveDoor", "MicrowaveWindow", "MicrowaveHandle",
	"MicrowavePanel", "MicrowaveDisplay", "MicrowaveButton", "AirFryerTop", "AirFryerDisplay", "AirFryerBasket",
	"AirFryerHandle", "AirFryerLine", "BlenderKnob", "BlenderCollar", "BlenderJar", "BlenderLid",
]

@export var desk_chair_path: NodePath = ^"Bedroom/Furniture/DeskChair"
@export var city_path: NodePath = ^"City"

## The apartment's floor, from its floor to the top of its roof slab, and its
## width, in the city's space (Residencial Aurora's own space).
const OWN_FLOOR_Y := Vector2(15.9, 19.0)
const OWN_FLOOR_X := Vector2(-6.9, 6.9)


func _ready() -> void:
	_open_own_floor()
	for node_name in LEVEL:
		for mesh_instance: MeshInstance3D in get_node(node_name).find_children("*", "MeshInstance3D", true, false):
			if not _skip(mesh_instance.name):
				mesh_instance.create_convex_collision(true, false)
	var seat := Seat.new()
	seat.name = "DeskChairSeat"
	add_child(seat)
	seat.setup(get_node(desk_chair_path))


func _skip(mesh_name: String) -> bool:
	for prefix in NO_COLLISION:
		if mesh_name.begins_with(prefix):
			return true
	return false


## Residencial Aurora is one solid block in the city, which would wall the
## apartment in. Swap it for the parts around the apartment (below, above
## and the strips beside it; the back is left open so the north windows look
## out over the courtyard behind the building), and hide the windows of this floor,
## which would sit in front of the balcony.
func _open_own_floor() -> void:
	var aurora: Node3D = get_node(city_path).get_node("Buildings/ApartmentBuilding")
	var wall: MeshInstance3D = aurora.get_node("Wall")
	var block := wall.mesh as BoxMesh
	wall.visible = false
	for mesh_instance: MeshInstance3D in aurora.find_children("*", "MeshInstance3D", false, false):
		var y := mesh_instance.position.y
		if y > OWN_FLOOR_Y.x - 0.5 and y < OWN_FLOOR_Y.y + 0.5:
			mesh_instance.visible = false
	var x0 := -block.size.x / 2
	var x1 := block.size.x / 2
	var z0 := wall.position.z - block.size.z / 2
	var z1 := wall.position.z + block.size.z / 2
	var y0 := OWN_FLOOR_Y.x
	var y1 := OWN_FLOOR_Y.y
	var parts := [
		[Vector3(x0, 0.0, z0), Vector3(x1, y0, z1)],
		[Vector3(x0, y1, z0), Vector3(x1, block.size.y, z1)],
		[Vector3(x0, y0, z0), Vector3(OWN_FLOOR_X.x, y1, z1)],
		[Vector3(OWN_FLOOR_X.y, y0, z0), Vector3(x1, y1, z1)],
	]
	for part in parts:
		var box := BoxMesh.new()
		box.size = part[1] - part[0]
		box.material = block.material
		var piece := MeshInstance3D.new()
		piece.name = "WallAroundApartment"
		piece.mesh = box
		piece.position = (part[0] + part[1]) / 2
		aurora.add_child(piece)
