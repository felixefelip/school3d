extends CharacterBody3D
## Third-person player.
## WASD: walk | Shift: run | Mouse: orbit the camera | E: interact (doors, chairs)
## Right mouse button (or Tab): capture/release the mouse | Esc: release

## Walking speed (m/s). 1.05 is the stride measured in the walk animation,
## so the feet don't slide on the floor.
@export var speed: float = 1.05
## Running speeds up both movement and animation by the same factor.
@export var run_multiplier: float = 1.8
@export var mouse_sensitivity: float = 0.003
## How fast the character turns toward the movement direction.
@export var turn_speed: float = 10.0
## Blend time between idle and walking (s).
@export var blend_time: float = 0.2
## How close (m) the player must be to use something in the "interactable" group.
@export var interact_distance: float = 1.5
## How far (m) the chair is pulled back so she can sit without hitting the desk.
@export var chair_pull: float = 0.35

## Name of the walk animation inside the imported model.
const WALK := "Walk"
const IDLE := "Idle"
const SIT := "Sit"
const SIT_LENGTH := 1.0
## Hips position in the seated pose, relative to the feet (the player origin).
## The seat ends up right under the hips.
const SEATED_HIPS := Vector3(0.0, 0.50, -0.29)
## Sit animation keyframes. "hips" is the Hips bone position; "pitch" is how
## far each bone is tilted forward around the X axis, in degrees, measured in
## the model's space (not relative to its parent). Positive tips the top of a
## bone forward, so legs swing forward with negative values. Bones left out
## stay upright.
const SIT_POSES := [
	{
		"time": 0.0,
		"hips": Vector3(0.0, 0.74, 0.0),
		"pitch": {},
	},
	{
		"time": 0.5,
		"hips": Vector3(0.0, 0.62, -0.18),
		"pitch": {
			"Spine": 25.0, "Chest": 35.0, "Neck": 25.0, "Head": 15.0,
			"Thigh.L": -45.0, "Thigh.R": -45.0, "Shin.L": 6.0, "Shin.R": 6.0,
			"UpperArm.L": -40.0, "UpperArm.R": -40.0,
			"Forearm.L": -55.0, "Forearm.R": -55.0, "Hand.L": -55.0, "Hand.R": -55.0,
		},
	},
	{
		"time": SIT_LENGTH,
		"hips": SEATED_HIPS,
		"pitch": {
			"Spine": 5.0, "Chest": 8.0, "Neck": 5.0,
			"Thigh.L": -78.0, "Thigh.R": -78.0,
			"UpperArm.L": -15.0, "UpperArm.R": -15.0,
			"Forearm.L": -60.0, "Forearm.R": -60.0, "Hand.L": -60.0, "Hand.R": -60.0,
		},
	},
]

enum State { FREE, BUSY, SEATED }

@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Skeleton3D
@onready var animation: AnimationPlayer = $Model/AnimationPlayer
@onready var collision: CollisionShape3D = $CollisionShape
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/CameraArm
@onready var prompt: Label = $HUD/Prompt

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Nearest interactable in range, or null.
var _interactable: Node = null
var _state := State.FREE
## The seat she is using, and where she stood before sitting down.
var _seat: Node = null
var _stand_position: Vector3


func _ready() -> void:
	_use_vertex_colors()
	animation.get_animation(WALK).loop_mode = Animation.LOOP_LINEAR
	_create_idle_animation()
	_create_sit_animation()
	animation.play(IDLE)
	camera_arm.add_excluded_object(get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## The character's colors are stored in the mesh vertices, but the importer
## doesn't enable that option on her materials (it does on the school's).
## Without this she renders all white.
func _use_vertex_colors() -> void:
	for mesh_instance: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		for i in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.mesh.surface_get_material(i) as StandardMaterial3D
			if material:
				material.vertex_color_use_as_albedo = true


## The model only ships with the walk animation. To stand still, we build an
## animation from the skeleton's rest pose so we can blend smoothly into it.
func _create_idle_animation() -> void:
	var walk := animation.get_animation(WALK)
	var idle := Animation.new()
	for i in walk.get_track_count():
		var path := walk.track_get_path(i)
		var bone := skeleton.find_bone(path.get_concatenated_subnames())
		if bone < 0:
			continue
		var rest := skeleton.get_bone_rest(bone)
		var type := walk.track_get_type(i)
		var track := idle.add_track(type)
		idle.track_set_path(track, path)
		match type:
			Animation.TYPE_POSITION_3D:
				idle.position_track_insert_key(track, 0.0, rest.origin)
			Animation.TYPE_ROTATION_3D:
				idle.rotation_track_insert_key(track, 0.0, rest.basis.get_rotation_quaternion())
			Animation.TYPE_SCALE_3D:
				idle.scale_track_insert_key(track, 0.0, rest.basis.get_scale())
	animation.get_animation_library("").add_animation(IDLE, idle)


## Builds the stand-to-sit animation from SIT_POSES. Every bone's rest
## rotation is zero, so a bone's local rotation is just its pitch minus its
## parent's pitch. Standing up plays it backwards.
func _create_sit_animation() -> void:
	var sit := Animation.new()
	sit.length = SIT_LENGTH
	var skeleton_path := String(animation.get_node(animation.root_node).get_path_to(skeleton))
	var hips_track := sit.add_track(Animation.TYPE_POSITION_3D)
	sit.track_set_path(hips_track, NodePath(skeleton_path + ":Hips"))
	sit.track_set_interpolation_type(hips_track, Animation.INTERPOLATION_CUBIC)
	for pose: Dictionary in SIT_POSES:
		sit.position_track_insert_key(hips_track, pose.time, pose.hips)
	for bone in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(bone)
		var parent := skeleton.get_bone_parent(bone)
		var track := sit.add_track(Animation.TYPE_ROTATION_3D)
		sit.track_set_path(track, NodePath(skeleton_path + ":" + bone_name))
		sit.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		for pose: Dictionary in SIT_POSES:
			var pitch: float = pose.pitch.get(bone_name, 0.0)
			if parent >= 0:
				pitch -= pose.pitch.get(skeleton.get_bone_name(parent), 0.0)
			sit.rotation_track_insert_key(track, pose.time, Quaternion(Vector3.RIGHT, deg_to_rad(pitch)))
	animation.get_animation_library("").add_animation(SIT, sit)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x - event.relative.y * mouse_sensitivity, -1.2, 0.4)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_toggle_mouse()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif event.physical_keycode == KEY_TAB:
			_toggle_mouse()
		elif event.physical_keycode == KEY_E:
			if _state == State.SEATED:
				stand_up()
			elif _state == State.FREE and _interactable:
				_interactable.interact(self)
			_update_prompt()


func _toggle_mouse() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if _state != State.FREE:
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	var input := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		input.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input.x += 1.0

	# Direction relative to the camera, ignoring its vertical tilt.
	var direction := camera_pivot.global_basis * Vector3(input.x, 0.0, input.y)
	direction.y = 0.0
	direction = direction.normalized()

	if direction != Vector3.ZERO:
		var running := Input.is_physical_key_pressed(KEY_SHIFT)
		var scale := run_multiplier if running else 1.0
		velocity.x = direction.x * speed * scale
		velocity.z = direction.z * speed * scale
		# The model faces +Z.
		model.rotation.y = lerp_angle(model.rotation.y, atan2(direction.x, direction.z), turn_speed * delta)
		if animation.current_animation != WALK:
			animation.play(WALK, blend_time)
		animation.speed_scale = scale
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		if animation.current_animation != IDLE:
			animation.speed_scale = 1.0
			animation.play(IDLE, blend_time)

	move_and_slide()
	_find_interactable()


## Pulls the chair back, stands in front of it with her back to it, sits
## down and scoots in together with the chair.
func sit_on(seat: Node) -> void:
	if _state != State.FREE:
		return
	_state = State.BUSY
	_seat = seat
	_stand_position = global_position
	collision.disabled = true
	velocity = Vector3.ZERO
	animation.speed_scale = 1.0

	var chair: Node3D = seat.chair
	var rest: Transform3D = seat.rest_transform
	var forward := rest.basis.z.normalized()
	var pulled := rest.origin - forward * chair_pull
	var feet_offset := forward * -SEATED_HIPS.z
	var facing := model.rotation.y + wrapf(atan2(forward.x, forward.z) - model.rotation.y, -PI, PI)

	animation.play(WALK, blend_time)
	var tween := create_tween()
	tween.tween_property(self, "global_position", pulled + feet_offset, 0.5)
	tween.parallel().tween_property(model, "rotation:y", facing, 0.5)
	tween.parallel().tween_property(chair, "global_position", pulled, 0.5)
	tween.tween_callback(animation.play.bind(SIT, blend_time))
	tween.tween_interval(SIT_LENGTH)
	tween.tween_property(self, "global_position", rest.origin + feet_offset, 0.4)
	tween.parallel().tween_property(chair, "global_position", rest.origin, 0.4)
	tween.tween_callback(_finish_sitting)


func _finish_sitting() -> void:
	_state = State.SEATED
	_update_prompt()


## The same steps as sit_on, backwards. She ends up where she stood before
## sitting, and the chair goes back under the desk.
func stand_up() -> void:
	if _state != State.SEATED:
		return
	_state = State.BUSY
	_update_prompt()

	var chair: Node3D = _seat.chair
	var rest: Transform3D = _seat.rest_transform
	var forward := rest.basis.z.normalized()
	var pulled := rest.origin - forward * chair_pull
	var feet_offset := forward * -SEATED_HIPS.z
	var way_back := _stand_position - (pulled + feet_offset)
	var facing := model.rotation.y + wrapf(atan2(way_back.x, way_back.z) - model.rotation.y, -PI, PI)

	var tween := create_tween()
	tween.tween_property(self, "global_position", pulled + feet_offset, 0.4)
	tween.parallel().tween_property(chair, "global_position", pulled, 0.4)
	tween.tween_callback(animation.play_backwards.bind(SIT, blend_time))
	tween.tween_interval(SIT_LENGTH)
	tween.tween_callback(animation.play.bind(WALK, blend_time))
	tween.tween_property(self, "global_position", _stand_position, 0.5)
	tween.parallel().tween_property(model, "rotation:y", facing, 0.3)
	tween.tween_callback(animation.play.bind(IDLE, blend_time))
	tween.tween_property(chair, "global_position", rest.origin, 0.4)
	tween.tween_callback(_finish_standing)


func _finish_standing() -> void:
	collision.disabled = false
	_seat = null
	_state = State.FREE
	_update_prompt()


func _find_interactable() -> void:
	var nearest: Node = null
	var nearest_distance := interact_distance
	for node in get_tree().get_nodes_in_group("interactable"):
		var offset: Vector3 = node.get_interaction_point() - global_position
		offset.y = 0.0
		if offset.length() < nearest_distance:
			nearest = node
			nearest_distance = offset.length()
	if nearest != _interactable:
		_interactable = nearest
		_update_prompt()


func _update_prompt() -> void:
	match _state:
		State.SEATED:
			prompt.visible = true
			prompt.text = "[E] Stand up"
		State.BUSY:
			prompt.visible = false
		State.FREE:
			prompt.visible = _interactable != null
			if _interactable:
				prompt.text = "[E] " + _interactable.get_prompt()
