extends GdUnitTestSuite
## The clock and calendar. Each test uses a fresh GameClock with the clock
## stopped, so the real autoload (and the current scene) are left alone.

const GameClockScript := preload("res://scripts/game_clock.gd")


func _new_clock() -> Node:
	var clock: Node = auto_free(GameClockScript.new())
	clock.running = false
	add_child(clock)
	return clock


func test_starts_on_monday_spring_1_at_6_am() -> void:
	var clock := _new_clock()
	assert_str(clock.date_text()).is_equal("Mon. 1")
	assert_str(clock.season_name()).is_equal("Spring")
	assert_int(clock.year).is_equal(1)
	assert_str(clock.time_text()).is_equal("6:00 am")


func test_formats_the_time() -> void:
	assert_str(GameClockScript.format_time(6 * 60)).is_equal("6:00 am")
	assert_str(GameClockScript.format_time(12 * 60)).is_equal("12:00 pm")
	assert_str(GameClockScript.format_time(13 * 60 + 10)).is_equal("1:10 pm")
	assert_str(GameClockScript.format_time(24 * 60)).is_equal("12:00 am")
	assert_str(GameClockScript.format_time(25 * 60 + 30)).is_equal("1:30 am")
	assert_str(GameClockScript.format_time(GameClockScript.PASS_OUT)).is_equal("3:00 am")


func test_advance_moves_the_clock_and_tells_the_hud() -> void:
	var clock := _new_clock()
	var got := []
	clock.time_changed.connect(func(value: int) -> void: got.append(value))
	clock.advance(10)
	assert_int(clock.minutes).is_equal(6 * 60 + 10)
	assert_array(got).contains_exactly([6 * 60 + 10])


func test_ten_minutes_pass_every_seven_seconds() -> void:
	var clock := _new_clock()
	clock.running = true
	clock._process(GameClockScript.SECONDS_PER_STEP - 0.1)
	assert_int(clock.minutes).is_equal(6 * 60)
	clock._process(0.2)
	assert_int(clock.minutes).is_equal(6 * 60 + 10)


func test_the_clock_stops_while_paused() -> void:
	var clock := _new_clock()
	clock.running = true
	get_tree().paused = true
	clock._process(30.0)
	get_tree().paused = false
	assert_int(clock.minutes).is_equal(6 * 60)


func test_passes_out_at_3_am() -> void:
	var clock := _new_clock()
	clock.minutes = GameClockScript.PASS_OUT - 10
	assert_bool(clock.should_pass_out()).is_false()
	clock.minutes = GameClockScript.PASS_OUT
	assert_bool(clock.should_pass_out()).is_true()


func test_new_day_goes_to_6_am_of_the_next_day() -> void:
	var clock := _new_clock()
	clock.minutes = 23 * 60
	var started := [0]
	clock.day_started.connect(func() -> void: started[0] += 1)
	clock.start_new_day()
	assert_int(clock.minutes).is_equal(GameClockScript.WAKE_UP)
	assert_str(clock.date_text()).is_equal("Tue. 2")
	assert_int(started[0]).is_equal(1)


func test_seasons_and_years_roll_over() -> void:
	var clock := _new_clock()
	clock.day = 28
	clock.start_new_day()
	assert_str(clock.season_name()).is_equal("Summer")
	assert_int(clock.day).is_equal(1)
	clock.season = 3
	clock.day = 28
	clock.start_new_day()
	assert_str(clock.season_name()).is_equal("Spring")
	assert_int(clock.year).is_equal(2)
	assert_int(clock.day_index()).is_equal(4 * 28)


func test_week_goes_on_across_seasons() -> void:
	var clock := _new_clock()
	clock.day = 7
	assert_str(clock.weekday_name()).is_equal("Sunday")
	clock.day = 8
	assert_str(clock.weekday_name()).is_equal("Monday")
	clock.season = 1
	clock.day = 1
	assert_str(clock.weekday_name()).is_equal("Monday")  # 28 days is four weeks


func test_daylight() -> void:
	assert_float(GameClockScript.daylight(3 * 60)).is_equal(0.0)
	assert_float(GameClockScript.daylight(6 * 60 + 45)).is_equal_approx(0.5, 0.01)
	assert_float(GameClockScript.daylight(12 * 60)).is_equal(1.0)
	assert_float(GameClockScript.daylight(18 * 60 + 30)).is_equal_approx(0.5, 0.01)
	assert_float(GameClockScript.daylight(22 * 60)).is_equal(0.0)
