extends Control
## The pause menu (Esc): stops the game and offers the outfit menu, the
## relationships list and quitting. Esc or Resume goes back to the game.
## It runs while the tree is paused (process_mode ALWAYS in player.tscn).

@export var relationships_path: NodePath = ^"../RelationshipsWindow"

var _player: Node
var _panel := PanelContainer.new()
var _outfit: Button
var _relationships: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel.add_theme_stylebox_override("panel", UIStyle.frame())
	center.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)

	var title := Label.new()
	UIStyle.style_label(title, 30)
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	_add_button(column, "Resume", "Resume", resume)
	_outfit = _add_button(column, "Outfit", "Outfit", _on_outfit)
	_add_button(column, "Relationships", "Relationships", _on_relationships)
	_add_button(column, "Quit", "Quit game", func() -> void: get_tree().quit())

	_relationships = get_node(relationships_path)
	_relationships.closed.connect(_panel.show)
	hide()


func _add_button(column: Container, button_name: String, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = button_name
	button.text = text
	UIStyle.style_button(button)
	button.custom_minimum_size = Vector2(240, 44)
	button.pressed.connect(action)
	column.add_child(button)
	return button


## `can_dress`: the outfit menu only opens while she stands (not seated).
func open(player: Node, can_dress: bool) -> void:
	_player = player
	_outfit.disabled = not can_dress
	_panel.show()
	show()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume() -> void:
	_relationships.hide()
	hide()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_outfit() -> void:
	resume()
	_player.open_outfit()


func _on_relationships() -> void:
	_panel.hide()
	_relationships.open()


func _unhandled_input(event: InputEvent) -> void:
	if visible and not _relationships.visible and event is InputEventKey and event.pressed \
			and not event.echo and event.physical_keycode == KEY_ESCAPE:
		resume()
		get_viewport().set_input_as_handled()
