extends PanelContainer
## The dressing menu (C): a turning 3D preview of the character next to her
## four clothing slots. Clean clothes are dragged from the hotbar onto the
## matching slot to wear them, and back to the hotbar to take them off.

const SLOT_NAMES := {
	Item.Slot.HEAD: "Head",
	Item.Slot.TOP: "Top",
	Item.Slot.LEGS: "Legs",
	Item.Slot.FEET: "Feet",
}
const PREVIEW_SIZE := Vector2i(240, 330)
## How fast the preview turns (rad/s).
const TURN_SPEED := 0.6

var _viewport := SubViewport.new()
var _model: Node3D


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.frame())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)

	var title := Label.new()
	UIStyle.style_label(title, 28)
	title.text = "Outfit"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	column.add_child(row)
	row.add_child(_build_preview())

	var slots := VBoxContainer.new()
	slots.add_theme_constant_override("separation", 8)
	slots.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(slots)
	for slot: Item.Slot in SLOT_NAMES:
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 10)
		slots.add_child(line)
		var inventory_slot := InventorySlot.new()
		line.add_child(inventory_slot)
		inventory_slot.setup(PlayerInventory.equipment, Outfit.slot_index(slot), slot)
		var label := Label.new()
		UIStyle.style_label(label, 20)
		label.text = SLOT_NAMES[slot]
		label.custom_minimum_size.x = 64
		line.add_child(label)

	var hint := Label.new()
	UIStyle.style_label(hint, 18)
	hint.text = "Drag clean clothes from your inventory  ·  [C] Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	hide()


## A small world of its own with a copy of the character, a light and a camera.
func _build_preview() -> Control:
	var container := SubViewportContainer.new()
	container.custom_minimum_size = PREVIEW_SIZE
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.size = PREVIEW_SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	container.add_child(_viewport)

	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.72, 0.68)
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	_viewport.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(-0.6, 0.6, 0.0)
	_viewport.add_child(light)
	var camera := Camera3D.new()
	camera.fov = 30.0
	_viewport.add_child(camera)
	camera.look_at_from_position(Vector3(0.0, 0.95, 3.4), Vector3(0.0, 0.78, 0.0))
	return container


## Shows a copy of the character's model (the same scene as hers).
func open(model_scene_path: String) -> void:
	if _model == null:
		_model = (load(model_scene_path) as PackedScene).instantiate()
		_viewport.add_child(_model)
		var skeleton: Skeleton3D = _model.get_node("Skeleton3D")
		StudentAnimations.use_vertex_colors(skeleton)
		var animation: AnimationPlayer = _model.get_node("AnimationPlayer")
		StudentAnimations.setup(animation, skeleton)
		animation.play(StudentAnimations.IDLE)
		PlayerInventory.equipment.changed.connect(_dress)
	_dress()
	show()
	reset_size()


func close() -> void:
	hide()


func _dress() -> void:
	Outfit.apply(_model, PlayerInventory.equipment)


func _process(delta: float) -> void:
	if visible and _model:
		_model.rotation.y += TURN_SPEED * delta
