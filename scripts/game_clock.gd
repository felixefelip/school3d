extends Node
## Time of day and calendar, like Stardew Valley. Autoload (GameClock).
##
## A day starts at 6:00 am and the clock moves in 10-minute steps, one every
## 7 real seconds (so a day lasts about 15 minutes). The calendar has four
## seasons of 28 days and a seven-day week. The clock stops while the game is
## paused.
##
## Going to bed (bed.gd) ends the day at any time. If the player is still up
## at 3:00 am she passes out, wherever she is, and wakes up next to her bed.
## Either way she wakes up the next morning at 6:00 am.

signal time_changed(minutes: int)
signal day_started

const SEASONS := ["Spring", "Summer", "Fall", "Winter"]
const WEEKDAYS := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const DAYS_PER_SEASON := 28
## Minutes since the day's midnight. Past midnight the count goes on
## (1:00 am is 25 * 60), so PASS_OUT is 3:00 am of the next morning.
const WAKE_UP := 6 * 60
const PASS_OUT := 27 * 60
const STEP := 10
## Real seconds per 10 game minutes.
const SECONDS_PER_STEP := 7.0

const HOME_SCENE := "res://scenes/house.tscn"
## Where she wakes up in HOME_SCENE (a node under SpawnPoints).
const BED_SPAWN := "Bedside"
const SLEEP_FADE := 1.2
const SceneDoor := preload("res://scripts/scene_door.gd")

var day := 1
var season := 0
var year := 1
var minutes := WAKE_UP
## False stops the clock (the tests use it; sleeping stops it too).
var running := true

var _elapsed := 0.0
var _sleeping := false
var _lit_scene: Node
var _message := Label.new()


func _ready() -> void:
	# Keeps running while the tree is paused during the sleep fade; the clock
	# itself checks for the pause menu.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 101
	add_child(layer)
	UIStyle.style_label(_message, 30)
	_message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.offset_top = 120
	_message.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_message.hide()
	layer.add_child(_message)


func _process(delta: float) -> void:
	var scene := get_tree().current_scene
	if scene != _lit_scene:
		_lit_scene = scene
		apply_light()
	if not running or _sleeping or get_tree().paused:
		return
	_elapsed += delta
	while _elapsed >= SECONDS_PER_STEP:
		_elapsed -= SECONDS_PER_STEP
		advance(STEP)


## Moves the clock forward. Passing PASS_OUT makes the player pass out.
func advance(game_minutes: int) -> void:
	minutes += game_minutes
	time_changed.emit(minutes)
	apply_light()
	if should_pass_out():
		sleep(true)


func should_pass_out() -> bool:
	return minutes >= PASS_OUT and not _sleeping


## The next morning: the date moves on one day and the clock goes to 6:00 am.
func start_new_day() -> void:
	minutes = WAKE_UP
	_elapsed = 0.0
	day += 1
	if day > DAYS_PER_SEASON:
		day = 1
		season += 1
		if season >= SEASONS.size():
			season = 0
			year += 1
	day_started.emit()
	time_changed.emit(minutes)
	apply_light()


## Ends the day: fades out, starts the next day and wakes the player up next
## to her bed. `passed_out`: she stayed up until 3:00 am.
func sleep(passed_out := false) -> void:
	if _sleeping:
		return
	_sleeping = true
	get_tree().paused = true
	var fade := SceneDoor.make_fade(self, 0.0)
	var tween := fade.create_tween()
	tween.tween_property(fade, "color:a", 1.0, SLEEP_FADE)
	await tween.finished
	start_new_day()
	SceneDoor._arrival_spawn = BED_SPAWN
	get_tree().change_scene_to_file(HOME_SCENE)
	await get_tree().scene_changed
	get_tree().paused = false
	var text := "You passed out from exhaustion...\n" if passed_out else ""
	_show_message(text + "%s, %s %d" % [weekday_name(), season_name(), day])
	tween = fade.create_tween()
	tween.tween_interval(0.6)
	tween.tween_property(fade, "color:a", 0.0, SLEEP_FADE)
	tween.tween_callback(fade.get_parent().queue_free)
	_sleeping = false


func is_sleeping() -> bool:
	return _sleeping


## Days since the game started (0 on the first day).
func day_index() -> int:
	return ((year - 1) * SEASONS.size() + season) * DAYS_PER_SEASON + day - 1


func weekday_name() -> String:
	return WEEKDAYS[day_index() % WEEKDAYS.size()]


func season_name() -> String:
	return SEASONS[season]


## "Mon. 1", like the date in Stardew Valley's clock.
func date_text() -> String:
	return "%s. %d" % [weekday_name().left(3), day]


## "6:00 am", "12:30 pm", "1:00 am" (past midnight).
static func format_time(value: int) -> String:
	var hour := (value / 60) % 24
	var minute := value % 60
	var suffix := "am" if hour < 12 else "pm"
	var shown := hour % 12
	if shown == 0:
		shown = 12
	return "%d:%02d %s" % [shown, minute, suffix]


func time_text() -> String:
	return format_time(minutes)


## How much daylight there is, from 0 (night) to 1 (day): sunrise from 6:00
## to 7:30 am, dusk from 5:00 to 8:00 pm.
static func daylight(value: int) -> float:
	var hour := value / 60.0
	if hour < 6.0 or hour >= 20.0:
		return 0.0
	if hour < 7.5:
		return (hour - 6.0) / 1.5
	if hour < 17.0:
		return 1.0
	return 1.0 - (hour - 17.0) / 3.0


## Dims the current scene's sun, sky and ambient light by the time of day.
## Each scene keeps its own daytime values (saved in metadata the first time).
func apply_light() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var light := daylight(minutes)
	var sun := scene.get_node_or_null("Sun") as DirectionalLight3D
	if sun:
		if not sun.has_meta("day_energy"):
			sun.set_meta("day_energy", sun.light_energy)
		var dusk := clampf(1.0 - absf(light - 0.5) * 2.0, 0.0, 1.0)
		sun.light_energy = sun.get_meta("day_energy") * lerpf(0.25, 1.0, light)
		sun.light_color = Color(1, 1, 1).lerp(Color(1.0, 0.68, 0.45), dusk * 0.8).lerp(Color(0.55, 0.62, 0.9), 1.0 - minf(light * 3.0, 1.0))
	var world := scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world and world.environment:
		if not world.has_meta("day_ambient"):
			# The scene's Environment is shared with every later load of the
			# scene, so work on a copy and keep the original at daytime values.
			world.environment = world.environment.duplicate()
		var environment := world.environment
		if not world.has_meta("day_ambient"):
			world.set_meta("day_ambient", environment.ambient_light_energy)
			world.set_meta("day_sky", environment.background_energy_multiplier)
		environment.ambient_light_energy = world.get_meta("day_ambient") * lerpf(0.9, 1.0, light)
		environment.background_energy_multiplier = world.get_meta("day_sky") * lerpf(0.45, 1.0, light)


func _show_message(text: String) -> void:
	_message.text = text
	_message.show()
	_message.modulate.a = 1.0
	var tween := _message.create_tween()
	tween.tween_interval(3.0)
	tween.tween_property(_message, "modulate:a", 0.0, 1.0)
	tween.tween_callback(_message.hide)
