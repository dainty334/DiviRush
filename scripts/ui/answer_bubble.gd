# One answer bubble on the Play screen. It shows a number, bobs gently, and tells the Play
# screen when it is tapped. It pops green with a sparkle when correct, and turns red and shakes when wrong.
class_name AnswerBubble  # Lets the Play screen write AnswerBubble.new().
extends Control  # A UI node that can draw and take taps.

signal tapped(bubble: AnswerBubble)  # Sent to the Play screen when the learner taps this bubble.

enum Mark { NONE, CHECK, CROSS }  # Small badge drawn on the bubble after an answer.

const SIZE := 320.0  # Bubble frame size in pixels (sprite sheet grid).

var value := 0  # The number on this bubble.
var _frames: Array[Texture2D] = []  # Frames of the current colour.
var _frame := 0  # 0 = resting bubble; 1-5 = popping.
var _mark := Mark.NONE  # Badge to draw.
var _shake := 0.0  # Sideways shake in pixels.
var _home := Vector2.ZERO  # Resting position; the bob moves around it.
var _bob_time := 0.0  # Time for the bob.
var _bob_phase := 0.0  # Start point of the bob, so bubbles do not move together.
var _locked := false  # true after an answer, so it cannot be tapped twice.
var _label: Label  # The number text.


# Runs when the bubble is made: sets its size and its centre point.
func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)  # Frame size.
	size = Vector2(SIZE, SIZE)  # Same size now.
	pivot_offset = size / 2.0  # Grow and shrink around the middle.


# Sets the number and colour. Called by the Play screen for each new item.
func setup(number: int, colour: String) -> void:
	value = number  # Remember the number.
	_frames = SpriteSheet.bubble(colour)  # Load this colour's frames.
	_bob_phase = randf() * TAU  # Random bob start.
	_label = UiKit.label(str(number), font_size_for(number), Palette.INK)  # Big dark number, smaller when it has more digits.
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill the bubble so the number is centred.
	_label.position.y -= 6.0  # Nudge up a little, since the bubble's outline is thicker at the bottom.
	add_child(_label)  # Show the number.


# Returns the font size for a number, so one, two and three digits all fit inside the bubble.
# Episode 4 bubbles can show numbers up to 100 (D-013).
static func font_size_for(number: int) -> int:
	if number < 10:  # One digit ...
		return 140  # ... the biggest.
	if number < 100:  # Two digits ...
		return 120  # ... a little smaller.
	return 96  # Three digits (only 100) ... smaller again, so it stays inside the round part.


# Places the bubble. Called by the Play screen with the top-left corner.
func place(at: Vector2) -> void:
	_home = at  # Remember the resting spot.
	position = at  # Move there now.


# Runs every frame: a gentle up-and-down bob while waiting for a tap.
func _process(delta: float) -> void:
	_bob_time += delta  # Count time.
	position = _home + Vector2(0.0, sin(_bob_time * 2.2 + _bob_phase) * 6.0)  # Float 6 pixels up and down.


# Tells Godot the bubble is round, so taps on the empty corners do not count.
func _has_point(point: Vector2) -> bool:
	return point.distance_to(size / 2.0) <= SIZE * 0.5  # Inside the circle only.


# Runs when the bubble gets a mouse or touch event: a tap sends `tapped`.
func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton  # Taps arrive as mouse clicks (touch is turned into mouse).
	if mouse != null and mouse.pressed and mouse.button_index == MOUSE_BUTTON_LEFT and not _locked:  # A new tap on a live bubble ...
		accept_event()  # ... is handled here,
		tapped.emit(self)  # ... and the Play screen is told.


# Stops the bubble taking taps. Called after any answer or a time-out.
func lock() -> void:
	_locked = true  # No more taps.


# Pops the bubble into view with a bounce, after a delay. Called when a new item appears.
func appear(delay: float) -> void:
	scale = Vector2.ZERO  # Start at zero size.
	var tween := create_tween()  # A tween on this bubble.
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)  # Grow with a bounce.


# Correct answer: turns green, shows a tick, bounces and sparkles.
func mark_correct() -> void:
	reveal()  # Green with a tick.
	var base := scale  # Its own size: full on the Play screen, smaller in the lessons (D-032).
	var tween := create_tween()  # A tween on this bubble.
	tween.tween_property(self, "scale", base * 1.18, 0.12).set_trans(Tween.TRANS_QUAD)  # Grow quickly.
	tween.tween_property(self, "scale", base, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)  # Spring back to its own size.
	for offset in [Vector2(-20, -30), Vector2(190, -10), Vector2(90, 200)]:  # Three sparkles around the bubble ...
		var sparkle := Sparkle.new()  # ... each a new burst,
		sparkle.position = offset  # ... at its own spot,
		add_child(sparkle)  # ... shown on top.


# Shows this bubble as the right answer (green with a tick) without the big celebration.
# Used to teach the answer after a wrong tap or a time-out.
func reveal() -> void:
	_frames = SpriteSheet.bubble("green")  # Green frames.
	_mark = Mark.CHECK  # Tick badge.
	queue_redraw()  # Draw again.


# Wrong answer: turns red, shows a cross and shakes.
func mark_wrong() -> void:
	_frames = SpriteSheet.bubble("red")  # Red frames.
	_mark = Mark.CROSS  # Cross badge.
	var tween := create_tween()  # A tween on this bubble.
	tween.tween_method(_set_shake, 0.0, 1.0, 0.45)  # Shake over 0.45 seconds.


# Sets the shake for a moment between 0 and 1: fast side-to-side moves that die down.
func _set_shake(t: float) -> void:
	_shake = sin(t * TAU * 5.0) * (1.0 - t) * 26.0  # Five quick swings, getting smaller.
	if _label != null:  # The number ...
		_label.position.x = _shake  # ... shakes with the bubble.
	queue_redraw()  # Draw at the new spot.


# Fades the bubble back, so the answered bubbles stand out.
func dim() -> void:
	create_tween().tween_property(self, "modulate:a", 0.45, 0.2)  # Fade to about half.


# Pops the bubble: plays frames 1 to 5 and fades the number. Called before the next item.
func burst() -> void:
	var tween := create_tween().set_parallel(true)  # Pop and fade together.
	tween.tween_method(_set_frame, 1.0, 5.99, 0.3)  # Frames 1 to 5.
	if _label != null:  # The number ...
		tween.tween_property(_label, "modulate:a", 0.0, 0.12)  # ... fades out fast.


# Shows one frame. Called by the tween with numbers from 1 to 5.99.
func _set_frame(value_in: float) -> void:
	_frame = int(value_in)  # Whole frame number.
	queue_redraw()  # Draw it.


# Draws the bubble frame and, after an answer, the tick or cross badge.
func _draw() -> void:
	if _frames.is_empty():  # Not set up yet ...
		return  # ... so draw nothing.
	var offset := Vector2(_shake, 0.0)  # Shake moves the drawing sideways.
	draw_texture_rect(_frames[_frame], Rect2(offset, size), false)  # The bubble picture.
	if _mark == Mark.NONE or _frame > 0:  # No badge, or the bubble is popping ...
		return  # ... so stop here.
	var badge := Vector2(262, 262) + offset  # Badge sits at the bottom right.
	draw_circle(badge, 44.0, Palette.WHITE, true, -1.0, true)  # White badge circle.
	draw_arc(badge, 44.0, 0.0, TAU, 40, Palette.INK, 8.0, true)  # Its dark outline.
	if _mark == Mark.CHECK:  # Correct ...
		draw_polyline(PackedVector2Array([badge + Vector2(-20, 2), badge + Vector2(-5, 18), badge + Vector2(22, -14)]), Palette.GREEN, 12.0, true)  # ... a green tick.
	else:  # Wrong ...
		draw_line(badge + Vector2(-16, -16), badge + Vector2(16, 16), Palette.RED, 12.0, true)  # ... a red cross,
		draw_line(badge + Vector2(16, -16), badge + Vector2(-16, 16), Palette.RED, 12.0, true)  # ... second stroke.
