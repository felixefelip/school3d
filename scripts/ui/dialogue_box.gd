extends PanelContainer
## What an NPC says when the player talks to her or him: the name, the line
## and, on the first talk of the day, whether the friendship went up or down.
## Sits above the hotbar and hides by itself.

## Seconds on screen.
const DURATION := 4.5
const WIDTH := 600
const TEXT_DARK := Color("4a2c14")
const GAIN := Color("2f7d32")
const LOSS := Color("b3261e")

var _name := Label.new()
var _line := Label.new()
var _friendship := Label.new()
var _timer := Timer.new()


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.tooltip())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	# Anchored above the prompt and the hotbar; it grows upwards to fit the text.
	offset_left = -WIDTH / 2.0
	offset_right = WIDTH / 2.0
	offset_top = -170
	offset_bottom = -170
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	for label: Label in [_name, _line, _friendship]:
		label.add_theme_color_override("font_color", TEXT_DARK)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
	_name.add_theme_font_size_override("font_size", 22)
	_line.add_theme_font_size_override("font_size", 19)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.custom_minimum_size.x = WIDTH - 24
	_friendship.add_theme_font_size_override("font_size", 16)
	_timer.one_shot = true
	_timer.timeout.connect(hide)
	add_child(_timer)
	hide()


## `change`: how the friendship changed (+1, -1); 0 shows no friendship line.
func show_line(npc_name: String, line: String, change: int) -> void:
	_name.text = npc_name
	_line.text = "\"%s\"" % line
	_friendship.visible = change != 0
	_friendship.text = "%+d friendship" % change
	_friendship.add_theme_color_override("font_color", GAIN if change > 0 else LOSS)
	show()
	# The wrapped line only knows its height once laid out.
	reset_size.call_deferred()
	_timer.start(DURATION)
