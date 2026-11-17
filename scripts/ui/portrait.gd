class_name Portrait
extends PanelContainer
## A character's face, rendered from its model in a small 3D world of its own
## (like the outfit menu's preview), framed on the head bone. People the
## player hasn't met yet show as a dark silhouette.

const SIZE := Vector2i(84, 84)
## From the head bone to the middle of the face, and how far the camera is.
const FACE_OFFSET := Vector3(0.0, 0.05, 0.0)
const DISTANCE := 0.75
const SILHOUETTE := Color(0.12, 0.08, 0.05)

var _container := SubViewportContainer.new()
var _viewport := SubViewport.new()


func _init() -> void:
	add_theme_stylebox_override("panel", UIStyle.slot(false))
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.custom_minimum_size = SIZE
	_container.stretch = true
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_container)
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.size = SIZE
	_container.add_child(_viewport)


## Shows the face of the model at `model_path` (a character .glb or scene).
func setup(model_path: String, known: bool) -> void:
	_container.modulate = Color.WHITE if known else SILHOUETTE
	if model_path == "" or not ResourceLoader.exists(model_path):
		return
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.8, 0.77, 0.72)
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.environment = environment
	_viewport.add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation = Vector3(-0.4, 0.5, 0.0)
	_viewport.add_child(light)

	var model: Node3D = (load(model_path) as PackedScene).instantiate()
	_viewport.add_child(model)
	var skeleton: Skeleton3D = model.get_node("Skeleton3D")
	StudentAnimations.use_vertex_colors(skeleton)
	var head := skeleton.find_bone("Head")
	var face := FACE_OFFSET
	if head >= 0:
		face += skeleton.get_bone_global_rest(head).origin
	var camera := Camera3D.new()
	camera.fov = 30.0
	_viewport.add_child(camera)
	camera.look_at_from_position(face + Vector3(0.0, 0.0, DISTANCE), face)
