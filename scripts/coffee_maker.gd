extends Node
## The kitchen coffee maker. E starts brewing: a horizontal progress bar floats
## above the machine, its light turns red and the carafe fills up. When it's
## done the light turns green, and E takes a cup of coffee into the player's
## inventory.

enum State { IDLE, BREWING, READY }

## The machine; the progress bar floats above it.
@export var target_path: NodePath
## From the machine to the spot in front of it, where the player stands.
@export var interaction_offset := Vector3.ZERO
## The coffee inside the carafe (a cylinder); it grows as the coffee brews.
@export var coffee_path: NodePath
## The power light: red while brewing, green when the coffee is ready.
@export var light_path: NodePath
@export var brew_time := 6.0
## What the player gets.
@export var item: Item

const BAR_SIZE := Vector2(170, 16)
const BAR_HEIGHT := 0.45
const COFFEE_FILL := Color("6b3b1f")
const LIGHT_BREWING := Color(1.0, 0.25, 0.15)
const LIGHT_READY := Color(0.2, 1.0, 0.3)

var state := State.IDLE

var _elapsed := 0.0
var _target: Node3D
var _coffee: Node3D
var _light: Node3D
var _coffee_rest: Transform3D
var _light_material: StandardMaterial3D
var _panel := PanelContainer.new()
var _bar := ProgressBar.new()


func _ready() -> void:
	_target = get_node(target_path)
	_coffee = get_node(coffee_path)
	_light = get_node(light_path)
	_coffee_rest = _coffee.transform
	# Its own copy, so changing the color doesn't touch other meshes.
	var mesh_instance := _light as MeshInstance3D
	_light_material = mesh_instance.mesh.surface_get_material(0).duplicate()
	mesh_instance.material_override = _light_material
	_set_coffee_level(0.0)
	_light.visible = false
	_build_bar()
	add_to_group("interactable")


func _build_bar() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_panel.add_theme_stylebox_override("panel", UIStyle.frame())
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	_panel.add_child(column)
	var label := Label.new()
	UIStyle.style_label(label, 16)
	label.text = "Brewing coffee..."
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(label)
	_bar.custom_minimum_size = BAR_SIZE
	_bar.show_percentage = false
	_bar.max_value = 1.0
	_bar.add_theme_stylebox_override("background", UIStyle.bar_background())
	_bar.add_theme_stylebox_override("fill", UIStyle.bar_fill(COFFEE_FILL))
	column.add_child(_bar)
	_panel.hide()


func get_interaction_point() -> Vector3:
	return _target.global_position + interaction_offset


## Empty while brewing: there's nothing to do until it's done.
func get_prompt() -> String:
	match state:
		State.IDLE:
			return "Make coffee"
		State.READY:
			return "Take coffee" if PlayerInventory.inventory.items.has(null) else "Take coffee (inventory full)"
	return ""


func interact(_by: Node3D) -> void:
	match state:
		State.IDLE:
			state = State.BREWING
			_elapsed = 0.0
			_set_light(LIGHT_BREWING)
		State.READY:
			if PlayerInventory.inventory.add(item.duplicate()):
				state = State.IDLE
				_set_coffee_level(0.0)
				_light.visible = false


func _process(delta: float) -> void:
	if state != State.BREWING:
		_panel.hide()
		return
	_elapsed += delta
	var progress := minf(_elapsed / brew_time, 1.0)
	_bar.value = progress
	_set_coffee_level(progress)
	if progress >= 1.0:
		state = State.READY
		_set_light(LIGHT_READY)
		_panel.hide()
		return
	_place_bar()


## Keeps the bar over the machine on screen; hidden when the machine is
## behind the camera.
func _place_bar() -> void:
	var camera := get_viewport().get_camera_3d()
	var point := _target.global_position + Vector3.UP * BAR_HEIGHT
	if camera == null or camera.is_position_behind(point):
		_panel.hide()
		return
	_panel.reset_size()
	_panel.position = camera.unproject_position(point) - _panel.size / 2.0
	_panel.show()


func _set_light(color: Color) -> void:
	_light_material.albedo_color = color
	_light_material.emission = color
	_light.visible = true


## Fills the carafe from the bottom: 0 is empty, 1 is full.
func _set_coffee_level(level: float) -> void:
	_coffee.visible = level > 0.01
	var mesh := (_coffee as MeshInstance3D).mesh as CylinderMesh
	var bottom := _coffee_rest.origin.y - mesh.height / 2.0
	_coffee.transform = _coffee_rest
	_coffee.scale.y = maxf(level, 0.01)
	_coffee.position.y = bottom + mesh.height * _coffee.scale.y / 2.0
