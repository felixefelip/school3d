extends StaticBody3D
## A student that isn't controlled by the player. She stands still where she
## is placed, or, when chair_path is set, sits on that chair.
## Seated students must come before the Seats node in the scene, so the chair
## is already taken when the seats are created.

@export var chair_path: NodePath

@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Skeleton3D
@onready var animation: AnimationPlayer = $Model/AnimationPlayer
@onready var collision: CollisionShape3D = $CollisionShape


func _ready() -> void:
	StudentAnimations.use_vertex_colors(skeleton)
	StudentAnimations.setup(animation, skeleton)
	if chair_path.is_empty():
		animation.play(StudentAnimations.IDLE)
		return

	var chair := get_node(chair_path) as Node3D
	chair.set_meta("occupied", true)
	var forward := chair.global_basis.z.normalized()
	global_position = chair.global_position + forward * -StudentAnimations.SEATED_HIPS.z
	rotation = Vector3(0.0, atan2(forward.x, forward.z), 0.0)
	# The chair and the desk already block the way.
	collision.disabled = true
	animation.play(StudentAnimations.SIT)
	animation.seek(StudentAnimations.SIT_LENGTH, true)
