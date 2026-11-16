extends Node3D
## The player's apartment (one floor). Builds collision for the rooms and
## furniture on startup (they are simple shapes, so a convex hull per mesh is
## exact enough) and makes the desk chair sittable.

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
	"Grass", "BuildingFacade", "BuildingRoof", "CityBuilding",
]

@export var desk_chair_path: NodePath = ^"Bedroom/Furniture/DeskChair"


func _ready() -> void:
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
