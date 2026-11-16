extends CharacterBody3D
## Third-person player.
## WASD: walk | Shift: run | Mouse: orbit the camera
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

## Name of the walk animation inside the imported model.
const WALK := "Walk"
const IDLE := "Idle"

@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Skeleton3D
@onready var animation: AnimationPlayer = $Model/AnimationPlayer
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/CameraArm

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _ready() -> void:
	_use_vertex_colors()
	animation.get_animation(WALK).loop_mode = Animation.LOOP_LINEAR
	_create_idle_animation()
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


func _toggle_mouse() -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
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
