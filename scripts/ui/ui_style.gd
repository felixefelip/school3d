class_name UIStyle
extends RefCounted
## Colors and panel styles shared by the inventory UI: warm wood and
## parchment, like the menus in Stardew Valley.

const FRAME_BG := Color("8a5a2b")
const FRAME_BORDER := Color("5a3417")
const SLOT_BG := Color("f3d9a4")
const SLOT_BORDER := Color("b07a3c")
const SLOT_SELECTED := Color("e0402f")
const TEXT := Color("fff3dc")
const TEXT_OUTLINE := Color("3b2210")
const CLEAN := Color("3f7d3a")
const DIRTY := Color("8a5a2b")


## The wooden frame around the hotbar and the storage window.
static func frame() -> StyleBoxFlat:
	return _box(FRAME_BG, FRAME_BORDER, 4, 10, 10)


## The parchment box of the item tooltip.
static func tooltip() -> StyleBoxFlat:
	return _box(SLOT_BG, FRAME_BORDER, 3, 6, 8)


static func slot(is_selected: bool) -> StyleBoxFlat:
	return _box(SLOT_BG, SLOT_SELECTED if is_selected else SLOT_BORDER, 4 if is_selected else 3, 6, 6)


static func style_button(button: Button) -> void:
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", TEXT_OUTLINE)
	button.add_theme_color_override("font_hover_color", TEXT_OUTLINE)
	button.add_theme_color_override("font_pressed_color", TEXT_OUTLINE)
	button.add_theme_color_override("font_disabled_color", Color(TEXT_OUTLINE, 0.5))
	button.add_theme_stylebox_override("normal", _box(SLOT_BG, SLOT_BORDER, 3, 6, 8))
	button.add_theme_stylebox_override("hover", _box(SLOT_BG.lightened(0.15), SLOT_SELECTED, 3, 6, 8))
	button.add_theme_stylebox_override("pressed", _box(SLOT_BG.darkened(0.1), SLOT_SELECTED, 3, 6, 8))
	button.add_theme_stylebox_override("disabled", _box(SLOT_BG.darkened(0.15), SLOT_BORDER, 3, 6, 8))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.custom_minimum_size = Vector2(160, 0)


static func style_label(label: Label, font_size: int) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_color_override("font_outline_color", TEXT_OUTLINE)
	label.add_theme_constant_override("outline_size", 6)


static func _box(bg: Color, border: Color, border_width: int, radius: int, margin: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = bg
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(margin)
	return box
