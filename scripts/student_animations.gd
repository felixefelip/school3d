class_name StudentAnimations
extends RefCounted
## Shared setup for the student character models (the player and the NPCs).
## They all use the same skeleton, which only ships with the walk animation;
## idle, sit and reach are built here from the skeleton.

## Name of the walk animation inside the imported model.
const WALK := "Walk"
const IDLE := "Idle"
const SIT := "Sit"
## Standing with the right hand on something in front of her at waist
## height (a locker door) and the left hand in front of the body.
const REACH := "Reach"
const SIT_LENGTH := 1.0
## Hips position in the seated pose, relative to the feet (the character's
## origin). The seat ends up right under the hips.
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

## Same convention as SIT_POSES.
const REACH_PITCH := {
	"UpperArm.R": -35.0, "Forearm.R": -90.0, "Hand.R": -90.0,
	"UpperArm.L": -15.0, "Forearm.L": -70.0, "Hand.L": -70.0,
	"Neck": 8.0, "Head": 12.0,
}


## The characters' colors are stored in the mesh vertices, but the importer
## doesn't enable that option on their materials (it does on the school's).
## Without this they render all white.
static func use_vertex_colors(skeleton: Skeleton3D) -> void:
	for mesh_instance: MeshInstance3D in skeleton.find_children("*", "MeshInstance3D", true, false):
		for i in mesh_instance.mesh.get_surface_count():
			var material := mesh_instance.mesh.surface_get_material(i) as StandardMaterial3D
			if material:
				material.vertex_color_use_as_albedo = true


## Makes the walk loop and adds the idle, sit and reach animations. Instances of the
## same model share one animation library, so each one is only added once.
static func setup(animation: AnimationPlayer, skeleton: Skeleton3D) -> void:
	animation.get_animation(WALK).loop_mode = Animation.LOOP_LINEAR
	var library := animation.get_animation_library("")
	if not library.has_animation(IDLE):
		library.add_animation(IDLE, _create_idle(animation, skeleton))
	if not library.has_animation(SIT):
		library.add_animation(SIT, _create_sit(animation, skeleton))
	if not library.has_animation(REACH):
		library.add_animation(REACH, _create_pose(animation, skeleton, [
			{"time": 0.0, "hips": Vector3(0.0, 0.74, 0.0), "pitch": REACH_PITCH},
		]))


## Idle is the skeleton's rest pose, as an animation so we can blend into it.
static func _create_idle(animation: AnimationPlayer, skeleton: Skeleton3D) -> Animation:
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
	return idle


## Builds the stand-to-sit animation from SIT_POSES. Standing up plays it
## backwards.
static func _create_sit(animation: AnimationPlayer, skeleton: Skeleton3D) -> Animation:
	var sit := _create_pose(animation, skeleton, SIT_POSES)
	sit.length = SIT_LENGTH
	return sit


## Builds an animation from keyframes in the SIT_POSES format. Every bone's
## rest rotation is zero, so a bone's local rotation is just its pitch minus
## its parent's pitch.
static func _create_pose(animation: AnimationPlayer, skeleton: Skeleton3D, poses: Array) -> Animation:
	var result := Animation.new()
	var skeleton_path := String(animation.get_node(animation.root_node).get_path_to(skeleton))
	var hips_track := result.add_track(Animation.TYPE_POSITION_3D)
	result.track_set_path(hips_track, NodePath(skeleton_path + ":Hips"))
	result.track_set_interpolation_type(hips_track, Animation.INTERPOLATION_CUBIC)
	for pose: Dictionary in poses:
		result.position_track_insert_key(hips_track, pose.time, pose.hips)
	for bone in skeleton.get_bone_count():
		var bone_name := skeleton.get_bone_name(bone)
		var parent := skeleton.get_bone_parent(bone)
		var track := result.add_track(Animation.TYPE_ROTATION_3D)
		result.track_set_path(track, NodePath(skeleton_path + ":" + bone_name))
		result.track_set_interpolation_type(track, Animation.INTERPOLATION_CUBIC)
		for pose: Dictionary in poses:
			var pitch: float = pose.pitch.get(bone_name, 0.0)
			if parent >= 0:
				pitch -= pose.pitch.get(skeleton.get_bone_name(parent), 0.0)
			result.rotation_track_insert_key(track, pose.time, Quaternion(Vector3.RIGHT, deg_to_rad(pitch)))
	return result
