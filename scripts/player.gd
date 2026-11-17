extends CharacterBody3D
## Third-person player.
## WASD: walk | Shift: run | Mouse: orbit the camera | E: interact (doors, chairs, wardrobe)
## 1-0 or mouse wheel: pick a hotbar slot | C: outfit (dress up)
## G: give the selected hotbar item to the NPC in front of her
## Right mouse button (or Tab): capture/release the mouse
## Esc: pause menu (outfit, relationships, quit)

## Stride speed (m/s): 1.05 is the stride measured in the walk animation, so
## at this speed with the animation at normal rate the feet don't slide.
@export var speed: float = 1.05
## Walking and running speed up both movement and animation by the same
## factor, so the feet still match the floor.
@export var walk_multiplier: float = 1.8
@export var run_multiplier: float = 3.2
@export var mouse_sensitivity: float = 0.003
## How fast the character turns toward the movement direction.
@export var turn_speed: float = 10.0
## Blend time between idle and walking (s).
@export var blend_time: float = 0.2
## How close (m) the player must be to use something in the "interactable" group.
@export var interact_distance: float = 1.5
## How far (m) the chair is pulled back so she can sit without hitting the desk.
@export var chair_pull: float = 0.35

const WALK := StudentAnimations.WALK
const IDLE := StudentAnimations.IDLE
const SIT := StudentAnimations.SIT
const SIT_LENGTH := StudentAnimations.SIT_LENGTH
const SEATED_HIPS := StudentAnimations.SEATED_HIPS

## MENU: a storage or the outfit window is open; the mouse is free to drag items.
enum State { FREE, BUSY, SEATED, MENU }

@onready var model: Node3D = $Model
@onready var skeleton: Skeleton3D = $Model/Skeleton3D
@onready var animation: AnimationPlayer = $Model/AnimationPlayer
@onready var collision: CollisionShape3D = $CollisionShape
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_arm: SpringArm3D = $CameraPivot/CameraArm
@onready var prompt: Label = $HUD/Prompt
@onready var storage_window: Control = $HUD/StorageWindow
@onready var outfit_window: Control = $HUD/OutfitWindow
@onready var pause_menu: Control = $HUD/PauseMenu

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
## Nearest interactable in range, or null.
var _interactable: Node = null
var _state := State.FREE
## The seat she is using, and where she stood before sitting down.
var _seat: Node = null
var _stand_position: Vector3


func _ready() -> void:
	StudentAnimations.use_vertex_colors(skeleton)
	StudentAnimations.setup(animation, skeleton)
	animation.play(IDLE)
	PlayerInventory.equipment.changed.connect(_dress)
	_dress()
	camera_arm.add_excluded_object(get_rid())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if _state == State.MENU:
		if event is InputEventKey and event.pressed and not event.echo \
				and event.physical_keycode in [KEY_E, KEY_ESCAPE, KEY_C]:
			close_menu()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var slot := _hotbar_key_slot(event.physical_keycode)
		if slot >= 0:
			PlayerInventory.selected = slot
			return
		if event.physical_keycode == KEY_C and _state == State.FREE:
			open_outfit()
			return
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			PlayerInventory.selected += 1
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			PlayerInventory.selected -= 1
			return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotation.y -= event.relative.x * mouse_sensitivity
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x - event.relative.y * mouse_sensitivity, -1.2, 0.4)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_toggle_mouse()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			open_pause_menu()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_TAB:
			_toggle_mouse()
		elif event.physical_keycode == KEY_E:
			if _state == State.SEATED:
				stand_up()
			elif _state == State.FREE and _interactable:
				_interactable.interact(self)
			_update_prompt()
		elif event.physical_keycode == KEY_G:
			if _state == State.FREE and _interactable and _interactable.has_method("give"):
				_interactable.give(self)
			_update_prompt()


## Keys 1-9 pick slots 1-9 and 0 picks slot 10; other keys give -1.
func _hotbar_key_slot(keycode: Key) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9:
		return keycode - KEY_1
	if keycode == KEY_0:
		return 9
	return -1


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
		var scale := run_multiplier if running else walk_multiplier
		velocity.x = direction.x * speed * scale
		velocity.z = direction.z * speed * scale
		model.rotation.y = lerp_angle(model.rotation.y, _model_yaw(direction), turn_speed * delta)
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
	var facing := model.rotation.y + wrapf(_model_yaw(forward) - model.rotation.y, -PI, PI)

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
	var facing := model.rotation.y + wrapf(_model_yaw(way_back) - model.rotation.y, -PI, PI)

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


## Opens a storage's window (e.g. the wardrobe) and frees the mouse to drag
## items. She stands still until it is closed with E or Esc.
func open_storage(storage: Node) -> void:
	if _state != State.FREE:
		return
	storage_window.open(storage)
	_enter_menu()


## Pauses the game and shows the pause menu (Esc). Not while she is busy
## sitting down or standing up.
func open_pause_menu() -> void:
	if _state != State.FREE and _state != State.SEATED:
		return
	prompt.visible = false
	pause_menu.open(self, _state == State.FREE)


## Opens the dressing menu (C).
func open_outfit() -> void:
	if _state != State.FREE:
		return
	outfit_window.open(model.scene_file_path)
	_enter_menu()


func _enter_menu() -> void:
	_state = State.MENU
	velocity = Vector3.ZERO
	animation.speed_scale = 1.0
	animation.play(IDLE, blend_time)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_prompt()


func _dress() -> void:
	Outfit.apply(model, PlayerInventory.equipment)


func close_menu() -> void:
	if _state != State.MENU:
		return
	storage_window.close()
	outfit_window.close()
	_state = State.FREE
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_update_prompt()


## The model's local rotation that makes it face a world direction. The model
## faces +Z, and the player node itself may be rotated in the scene.
func _model_yaw(world_direction: Vector3) -> float:
	return atan2(world_direction.x, world_direction.z) - global_rotation.y


func _find_interactable() -> void:
	var nearest: Node = null
	var nearest_distance := interact_distance
	for node in get_tree().get_nodes_in_group("interactable"):
		var offset: Vector3 = node.get_interaction_point() - global_position
		offset.y = 0.0
		if offset.length() < nearest_distance:
			nearest = node
			nearest_distance = offset.length()
	_interactable = nearest
	# Every frame, since an interactable's prompt can change on its own (the
	# coffee maker goes from "Make coffee" to nothing to "Take coffee").
	_update_prompt()


func _update_prompt() -> void:
	match _state:
		State.SEATED:
			prompt.visible = true
			prompt.text = "[E] Stand up"
		State.BUSY, State.MENU:
			prompt.visible = false
		State.FREE:
			var text: String = _interactable.get_prompt() if _interactable else ""
			var give: String = _interactable.get_give_prompt() \
					if _interactable and _interactable.has_method("get_give_prompt") else ""
			prompt.visible = text != "" or give != ""
			prompt.text = "   ".join(PackedStringArray(
					(["[E] " + text] if text != "" else []) + (["[G] " + give] if give != "" else [])))
