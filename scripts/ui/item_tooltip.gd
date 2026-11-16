extends PanelContainer
## Shows the name and description of the item under the mouse, next to the
## cursor, and whether a piece of clothing is clean or dirty. It only appears while the mouse is free (a storage window is open)
## and hides by itself when the mouse is captured again.

const OFFSET := Vector2(18, 18)
const TEXT_DARK := Color("4a2c14")

var _name := Label.new()
var _description := Label.new()
var _status := Label.new()


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.tooltip())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	for label: Label in [_name, _description, _status]:
		label.add_theme_color_override("font_color", TEXT_DARK)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
	_name.add_theme_font_size_override("font_size", 20)
	_description.add_theme_font_size_override("font_size", 15)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size.x = 220
	_status.add_theme_font_size_override("font_size", 15)
	hide()


func _process(_delta: float) -> void:
	var slot := get_viewport().gui_get_hovered_control() as InventorySlot
	var item := slot.item if slot else null
	if item == null or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or get_viewport().gui_is_dragging():
		hide()
		return
	_name.text = item.display_name
	_description.text = item.description
	_status.visible = item.is_clothing()
	_status.text = "Dirty: wash it in the washing machine" if item.dirty else "Clean"
	_status.add_theme_color_override("font_color", UIStyle.DIRTY if item.dirty else UIStyle.CLEAN)
	reset_size()
	# Keep the box on screen near the right and bottom edges.
	var screen := get_viewport().get_visible_rect().size
	var at := get_viewport().get_mouse_position() + OFFSET
	at.x = minf(at.x, screen.x - size.x - 4)
	at.y = minf(at.y, screen.y - size.y - 4)
	position = at
	show()
