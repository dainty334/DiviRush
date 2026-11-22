# Tests that the timer bar turns green -> yellow -> red as time runs out (D-008).
extends GutTest  # GUT gives this script its assert_* checks.


# Plenty of time left shows green.
func test_full_time_is_green() -> void:
	assert_true(TimerBar.colour_for(1.0).is_equal_approx(Palette.GREEN))  # Full bar = green (approx, since blending rounds a little).


# About a third of the time left shows yellow.
func test_a_third_left_is_yellow() -> void:
	assert_true(TimerBar.colour_for(0.38).is_equal_approx(Palette.YELLOW))  # Middle of the yellow band.


# Almost no time left shows red (the palette's pink-red).
func test_nearly_no_time_is_red() -> void:
	assert_true(TimerBar.colour_for(0.1).is_equal_approx(Palette.PINK))  # Low bar = red.
