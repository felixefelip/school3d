extends Node3D
## The neighbourhood around the apartment building: the main street, the new
## street that crosses it and street 3, with the school one block south.
## The neighbourhood itself is scenes/city.tscn (instanced as City), shared
## with the apartment for the view from its windows. This script builds
## collision for the blocks, buildings, cars and street furniture on startup
## (simple shapes, so a convex hull per mesh is exact enough). The invisible
## ramps that let the player step on and off the sidewalks are in the city
## scene (CurbRamps).

const LEVEL := ["City/Ground", "City/Buildings", "City/Cars", "City/Props"]
## Meshes flat on the ground, high above the player, too small to bump into or
## out of reach (rooftops, the distant city and the school yard behind the fence).
const NO_COLLISION := [
	"Window", "Sign", "Marking", "Crosswalk", "Manhole", "Headlight", "Taillight", "Plate",
	"Hubcap", "Mirror", "TreeCrown", "TreePit", "Flower", "Awning", "Canopy", "CityBuilding",
	"LampArm", "LampHead", "LampGlow", "Cornice", "Sill", "DoorFrame", "Handle", "Number",
	"TrafficLamp", "TrafficHousing", "UmbrellaTop", "Windshield", "Grate", "Plinth", "Menu",
	"BusSign", "Mailbox", "Stripe", "SchoolYard", "SchoolPath", "Court", "Flag", "Hoop",
	"FenceRail", "GateFrame", "SchoolRoofEdge", "Roof", "Antenna", "Neon",
]


func _ready() -> void:
	for node_name in LEVEL:
		for mesh_instance: MeshInstance3D in get_node(node_name).find_children("*", "MeshInstance3D", true, false):
			if not _skip(mesh_instance.name):
				mesh_instance.create_convex_collision(true, false)


func _skip(mesh_name: String) -> bool:
	for prefix in NO_COLLISION:
		if mesh_name.begins_with(prefix):
			return true
	return false
