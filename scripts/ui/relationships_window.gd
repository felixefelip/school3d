extends Control
## The relationships list, opened from the pause menu: everyone the player can
## get to know, with their face, friendship level, hearts and points.

signal closed

const TEXT_DARK := Color("4a2c14")
const MUTED := Color("8a6a4a")

var _list := VBoxContainer.new()


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UIStyle.frame())
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)

	var title := Label.new()
	UIStyle.style_label(title, 28)
	title.text = "Relationships"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_list.add_theme_constant_override("separation", 8)
	column.add_child(_list)

	var back := Button.new()
	back.name = "Back"
	back.text = "Back"
	UIStyle.style_button(back)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	column.add_child(back)
	hide()


func open() -> void:
	_refresh()
	show()


func close() -> void:
	hide()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	for npc_id: String in Relationships.list_people():
		_list.add_child(_row(npc_id))


## One person: face, name and where to find them on the left, hearts and
## points on the right.
func _row(npc_id: String) -> Control:
	var person: Dictionary = Relationships.people[npc_id]
	var value := Relationships.get_points(npc_id)
	var met: bool = Relationships.met.has(npc_id)

	var card := PanelContainer.new()
	card.name = npc_id
	card.add_theme_stylebox_override("panel", UIStyle.tooltip())
	card.custom_minimum_size.x = 560
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	var portrait := Portrait.new()
	portrait.name = "Portrait"
	portrait.setup(person.get("model", ""), met)
	row.add_child(portrait)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info)
	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = person.name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", TEXT_DARK)
	info.add_child(name_label)
	var details := Label.new()
	details.name = "Details"
	var level := Relationships.level_name(value) if met else "Not met yet"
	details.text = level + ("  ·  " + person.place if person.get("place", "") != "" else "")
	details.add_theme_font_size_override("font_size", 15)
	details.add_theme_color_override("font_color", MUTED)
	info.add_child(details)

	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(right)
	var hearts := HeartRow.new()
	hearts.name = "Hearts"
	hearts.total = Relationships.MAX_HEARTS
	hearts.filled = mini(value, Relationships.MAX_HEARTS)
	right.add_child(hearts)
	var points_label := Label.new()
	points_label.name = "Points"
	points_label.text = "%d %s" % [value, "point" if value == 1 else "points"]
	points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	points_label.add_theme_font_size_override("font_size", 15)
	points_label.add_theme_color_override("font_color", TEXT_DARK)
	right.add_child(points_label)
	return card
