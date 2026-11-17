extends StaticBody3D
## A student that isn't controlled by the player. She stands still where she
## is placed (optionally reaching into something in front of her, like a
## locker), or, when chair_path is set, sits on that chair.
## Seated students must come before the Seats node in the scene, so the chair
## is already taken when the seats are created.
##
## With a name she (or he) is someone the player can get to know: E talks to
## her, a name tag floats over her head, and the friendship points go up or
## down by how the player looks (see relationships.gd).

@export var chair_path: NodePath
## Standing only: hands on whatever is in front of her (e.g. her locker).
@export var reaching: bool = false
@export_group("Relationship")
## Shown on the name tag and in the dialogue. Empty: just a background student.
@export var npc_name := ""
## Key of her friendship points; defaults to the name in lower case.
@export var npc_id := ""
## What she says to a player in clean clothes, and in dirty ones.
@export var friendly_lines := PackedStringArray(["Hi! Nice to see you.", "Hey! Want to sit with us?"])
@export var rude_lines := PackedStringArray(["Ugh... is that a stain on your clothes?", "Could you... stand a bit further away?"])

@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Skeleton3D
@onready var animation: AnimationPlayer = $Model/AnimationPlayer
@onready var collision: CollisionShape3D = $CollisionShape


func _ready() -> void:
	StudentAnimations.use_vertex_colors(skeleton)
	StudentAnimations.setup(animation, skeleton)
	if npc_name != "":
		if npc_id == "":
			npc_id = npc_name.to_lower()
		add_to_group("interactable")
		_add_name_tag(not chair_path.is_empty())
	if chair_path.is_empty():
		animation.play(StudentAnimations.REACH if reaching else StudentAnimations.IDLE)
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


func get_interaction_point() -> Vector3:
	return global_position


func get_prompt() -> String:
	return "Talk to " + npc_name


func interact(_by: Node3D) -> void:
	Relationships.talk(npc_id, npc_name, friendly_lines, rude_lines)


func _add_name_tag(seated: bool) -> void:
	var tag := Label3D.new()
	tag.name = "NameTag"
	tag.text = npc_name
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.pixel_size = 0.004
	tag.font_size = 44
	tag.outline_size = 10
	tag.modulate = UIStyle.TEXT
	tag.outline_modulate = UIStyle.TEXT_OUTLINE
	tag.no_depth_test = false
	tag.position = Vector3(0, 1.55 if seated else 1.95, 0)
	add_child(tag)
