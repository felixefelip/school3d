extends Node
## Makes every chair in the school model sittable (the student chairs
## Chair01..Chair12 and the TeacherChair).

const Seat := preload("res://scripts/seat.gd")

@export var school_path: NodePath = ^"../School"


func _ready() -> void:
	for node in get_node(school_path).get_children():
		if node.name.begins_with("Chair") or node.name == "TeacherChair":
			var seat := Seat.new()
			seat.name = String(node.name) + "Seat"
			add_child(seat)
			seat.setup(node)
