# The sky background with soft bubbles floating up, shown behind every screen (D-009 "lively screens").
# Drawn in code each frame, which is lighter than one animated node per bubble.
class_name BubbleBackground  # Lets screens write BubbleBackground.new().
extends Control  # A UI node that can draw.

const COUNT := 16  # How many bubbles float at once.

var _bubbles: Array[Dictionary] = []  # Each bubble: x, y, r (size), speed, phase, ring.
var _time := 0.0  # Seconds since the screen opened, for the side-to-side sway.
var _sky := GradientTexture2D.new()  # The sky picture, blended from light to deep blue.


# Runs when the background is added to a screen: fills the screen and makes the first bubbles.
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Cover the whole screen, with no gaps at the edges.
	var gradient := Gradient.new()  # Colour blend for the sky.
	gradient.set_color(0, Palette.SKY_TOP)  # Light blue at the top ...
	gradient.set_color(1, Palette.SKY_BOTTOM)  # ... deep blue at the bottom.
	_sky.gradient = gradient  # Use the blend in the sky picture.
	_sky.fill_from = Vector2(0.5, 0.0)  # Blend starts at the top middle ...
	_sky.fill_to = Vector2(0.5, 1.0)  # ... and ends at the bottom middle.
	_sky.width = 4  # A tiny picture is enough; it is stretched to fill the screen.
	_sky.height = 256  # Enough steps for a smooth blend from top to bottom.
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Never block taps.
	for i in range(COUNT):  # Make each bubble ...
		_bubbles.append(_new_bubble(false))  # ... anywhere on screen to start.


# Makes one bubble. A new bubble starts below the screen; the first ones start anywhere.
func _new_bubble(from_bottom: bool) -> Dictionary:
	var area := get_viewport_rect().size  # Screen size.
	var radius := randf_range(14.0, 90.0)  # Small to big bubbles.
	return {  # The bubble's values.
		"x": randf_range(0.0, area.x),  # Across the screen.
		"y": area.y + radius if from_bottom else randf_range(0.0, area.y),  # Below the screen, or anywhere.
		"r": radius,  # Size.
		"speed": randf_range(30.0, 90.0),  # Pixels per second upwards.
		"phase": randf() * TAU,  # Start point of the sway.
		"ring": randf() < 0.3,  # About 1 in 3 is an outline ring instead of a filled bubble.
	}  # End of the list.


# Runs every frame: moves the bubbles up and redraws.
func _process(delta: float) -> void:
	_time += delta  # Count time for the sway.
	for i in range(_bubbles.size()):  # Each bubble ...
		var bubble := _bubbles[i]  # ... take it,
		bubble.y -= bubble.speed * delta  # ... move it up,
		if bubble.y < -bubble.r:  # ... and once it leaves the top,
			_bubbles[i] = _new_bubble(true)  # ... start a new one at the bottom.
	queue_redraw()  # Draw again with the new positions.


# Draws the sky gradient and every bubble.
func _draw() -> void:
	draw_texture_rect(_sky, Rect2(Vector2.ZERO, size), false)  # The sky, stretched over the whole screen.
	for bubble in _bubbles:  # Each bubble ...
		var at := Vector2(bubble.x + sin(_time * 0.8 + bubble.phase) * 12.0, bubble.y)  # ... sways a little side to side.
		if bubble.ring:  # An outline bubble ...
			draw_arc(at, bubble.r, 0.0, TAU, 48, Color(1, 1, 1, 0.35), 6.0, true)  # ... is a thin white ring.
		else:  # A filled bubble ...
			draw_circle(at, bubble.r, Color(1, 1, 1, 0.18), true, -1.0, true)  # ... is a soft white circle.
