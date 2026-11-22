# The Play screen timer bar. It shrinks as time runs out and turns green -> yellow -> red (D-008).
class_name TimerBar  # Lets the Play screen write TimerBar.new().
extends Control  # A UI node that can draw.

var ratio: float = 1.0:  # Share of time left: 1.0 = full, 0.0 = none.
	set(value):  # Whenever it changes ...
		ratio = clampf(value, 0.0, 1.0)  # ... keep it between 0 and 1,
		queue_redraw()  # ... and draw the bar again.

var _back := UiKit.box(Color(Palette.INK, 0.35), 32, 8)  # Dark see-through track behind the bar.
var _fill := StyleBoxFlat.new()  # The coloured part of the bar.


# Runs when the bar is made: sets its size and rounds the coloured part.
func _init() -> void:
	custom_minimum_size = Vector2(700, 64)  # Wide and thick, like the sample.
	size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Fill the row across.
	_fill.set_corner_radius_all(22)  # Rounded ends.
	_fill.anti_aliasing = true  # Smooth edges.
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Never block taps.


# Returns the bar colour for a share of time left: green when there is plenty, yellow at about
# half, red when it is nearly gone. Two short blends make the change smooth.
static func colour_for(share: float) -> Color:
	var colour := Palette.PINK.lerp(Palette.YELLOW, smoothstep(0.2, 0.3, share))  # Red -> yellow around 25 %.
	return colour.lerp(Palette.GREEN, smoothstep(0.45, 0.55, share))  # Yellow -> green around 50 %.


# Draws the track, the coloured part and a shine line.
func _draw() -> void:
	draw_style_box(_back, Rect2(Vector2.ZERO, size))  # The dark track.
	var inner := Rect2(10, 10, (size.x - 20) * ratio, size.y - 20)  # Coloured part, inside the track.
	if inner.size.x < 6.0:  # Too thin to draw nicely ...
		return  # ... so stop here.
	_fill.bg_color = colour_for(ratio)  # Pick the colour for the time left.
	draw_style_box(_fill, inner)  # The coloured part.
	var shine := Rect2(inner.position + Vector2(20, 7), Vector2(minf(inner.size.x * 0.5, 300.0), 9))  # A light streak on top.
	draw_rect(shine, Color(1, 1, 1, 0.5))  # Draw the streak.
