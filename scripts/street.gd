extends Node3D
## The street in front of the apartment building. Builds collision for the
## buildings, sidewalks, cars and street furniture on startup (simple shapes,
## so a convex hull per mesh is exact enough) and adds invisible ramps along
## the curbs so the player can step between the road and the sidewalks.

const LEVEL := ["Ground", "Buildings", "Cars", "Props"]
## Meshes flat on the ground, high above the player or too small to bump into.
const NO_COLLISION := [
	"Window", "Sign", "Marking", "Crosswalk", "Manhole", "Headlight", "Taillight", "Plate",
	"Hubcap", "Mirror", "TreeCrown", "TreePit", "Flower", "Awning", "Canopy", "CityBuilding",
	"LampArm", "LampHead", "LampGlow", "Cornice", "Sill", "DoorFrame", "Handle", "Number",
	"TrafficLamp", "TrafficHousing", "UmbrellaTop", "Windshield", "Grate", "Plinth", "Menu",
	"BusSign", "Mailbox", "Stripe",
]

## Sidewalk top is at y = 0 and the road at y = -CURB_HEIGHT.
const CURB_HEIGHT := 0.15
## How far the ramp reaches into the road (m).
const RAMP_LENGTH := 0.45
## The curbs run along X at these z, with the road on the given side.
const CURBS := [
	{"z": 4.0, "road_side": 1.0},
	{"z": 12.0, "road_side": -1.0},
]
const CURB_X_RANGE := Vector2(-41.0, 41.0)


func _ready() -> void:
	for node_name in LEVEL:
		for mesh_instance: MeshInstance3D in get_node(node_name).find_children("*", "MeshInstance3D", true, false):
			if not _skip(mesh_instance.name):
				mesh_instance.create_convex_collision(true, false)
	for curb in CURBS:
		_add_curb_ramp(curb.z, curb.road_side)


func _skip(mesh_name: String) -> bool:
	for prefix in NO_COLLISION:
		if mesh_name.begins_with(prefix):
			return true
	return false


## A wedge from the top of the curb down to the road, so the player's capsule
## slides up and down instead of hitting a step.
func _add_curb_ramp(z: float, road_side: float) -> void:
	var points := PackedVector3Array()
	for x in [CURB_X_RANGE.x, CURB_X_RANGE.y]:
		points.append(Vector3(x, 0.0, z))
		points.append(Vector3(x, -CURB_HEIGHT, z))
		points.append(Vector3(x, -CURB_HEIGHT, z + road_side * RAMP_LENGTH))
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	var body := StaticBody3D.new()
	body.name = "CurbRamp"
	body.add_child(collision)
	add_child(body)
