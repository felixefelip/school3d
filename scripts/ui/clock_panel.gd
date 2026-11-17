extends PanelContainer
## The date and time in the top right corner, like Stardew Valley's clock:
## "Mon. 1", "Spring, Year 1" and "6:00 am".

var _date := Label.new()
var _season := Label.new()
var _time := Label.new()


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.frame())
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -190
	offset_right = -16
	offset_top = 16
	grow_horizontal = Control.GROW_DIRECTION_BEGIN
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	for label: Label in [_date, _season, _time]:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_child(label)
	UIStyle.style_label(_date, 24)
	UIStyle.style_label(_season, 16)
	UIStyle.style_label(_time, 26)
	_date.name = "Date"
	_season.name = "Season"
	_time.name = "Time"
	GameClock.time_changed.connect(_on_time_changed)
	GameClock.day_started.connect(refresh)
	refresh()


func refresh() -> void:
	_date.text = GameClock.date_text()
	_season.text = "%s, Year %d" % [GameClock.season_name(), GameClock.year]
	_time.text = GameClock.time_text()


func _on_time_changed(_minutes: int) -> void:
	refresh()
