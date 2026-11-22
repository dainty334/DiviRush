# The 10 progress dots on the Play screen: green = correct, pink = wrong, white = now, faded = still to come.
class_name ProgressDots  # Lets the Play screen write ProgressDots.new().
extends Control  # A UI node that can draw.

const TOTAL := 10  # Items per Level (D-007).
const SPACING := 70.0  # Distance between dot centres, as in the sample.

var _results: Array[bool] = []  # true / false for each answered item.
var _current := 0  # Which item is showing now.


# Runs when the dots are made: sets their size.
func _init() -> void:
	custom_minimum_size = Vector2(760, 70)  # Room for 10 dots.
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Never block taps.


# Updates the dots. Called by the Play screen after each answer.
func show_state(results: Array[bool], current: int) -> void:
	_results = results.duplicate()  # Copy so later changes do not leak in.
	_current = current  # Remember which item is showing.
	queue_redraw()  # Draw again.


# Draws the 10 dots with dark outlines.
func _draw() -> void:
	var first_x := size.x / 2.0 - SPACING * (TOTAL - 1) / 2.0  # Centre the row.
	for i in range(TOTAL):  # Each dot.
		var at := Vector2(first_x + i * SPACING, size.y / 2.0)  # Its centre.
		var radius := 22.0  # Normal size.
		var colour := Color(Palette.INK, 0.25)  # Faded: still to come.
		if i < _results.size():  # Already answered ...
			colour = Palette.GREEN if _results[i] else Palette.PINK  # ... green if correct, pink if not.
		elif i == _current:  # The item showing now ...
			colour = Palette.WHITE  # ... is white,
			radius = 28.0  # ... and a little bigger.
		draw_circle(at, radius, colour, true, -1.0, true)  # The dot.
		draw_arc(at, radius, 0.0, TAU, 40, Palette.INK, 6.0, true)  # Its dark outline.
