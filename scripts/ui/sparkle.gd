# A one-time sparkle burst that plays the sparkle sprite sheet and then removes itself.
# Added on top of a bubble when the answer is correct.
class_name Sparkle  # Lets the answer bubble write Sparkle.new().
extends Control  # A UI node that can draw.

var _frames: Array[Texture2D] = []  # The 6 sparkle frames.
var _frame := 0  # The frame showing now.


# Runs when the sparkle is made: sets its size and lets taps pass through.
func _init() -> void:
	size = Vector2(160, 160)  # One sparkle frame.
	mouse_filter = Control.MOUSE_FILTER_IGNORE  # Never block taps.


# Runs when the sparkle is shown: plays the 6 frames once, then removes itself.
func _ready() -> void:
	_frames = SpriteSheet.sparkle()  # Load the frames.
	var tween := create_tween()  # A tween on this sparkle.
	tween.tween_method(_set_frame, 0.0, 5.99, 0.45)  # Step through frames 0 to 5.
	tween.tween_callback(queue_free)  # Then remove the sparkle.


# Shows one frame. Called by the tween with numbers from 0 to 5.99.
func _set_frame(value: float) -> void:
	_frame = int(value)  # Whole frame number.
	queue_redraw()  # Draw it.


# Draws the current frame.
func _draw() -> void:
	if not _frames.is_empty():  # Frames are loaded ...
		draw_texture_rect(_frames[_frame], Rect2(Vector2.ZERO, size), false)  # ... so draw this one.
