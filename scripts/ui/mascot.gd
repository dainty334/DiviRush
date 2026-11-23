# A talking student mascot (D-024, D-025): Ana or Migo, standing under a speech bubble. The mascot
# is quiet until tapped; each tap types the next line into the bubble, letter by letter, while the
# mouth opens and closes. A few seconds after the line is finished, the bubble fades away, so the
# screen stays clean. There is no voice.
class_name Mascot  # Lets the Main menu and tests write Mascot.new("Ana", lines).
extends VBoxContainer  # The speech bubble on top, the mascot underneath.

const PICTURE_SIZE := Vector2(300, 340)  # The mascot picture, the size of one sheet frame.
const BUBBLE_SIZE := Vector2(780, 190)  # The speech bubble, including its pointer.
const TAIL_HEIGHT := 28.0  # How far the bubble's pointer sticks down towards the mascot.

var mascot_name: String  # "Ana" or "Migo".
var lines: Array[String] = []  # Everything the mascot says, in order.
var line_index := -1  # Which line is showing now (-1: none yet, so the first tap says the greeting).
var _frames: Array[Texture2D] = []  # Mouth closed (0) and mouth open (1).
var _picture: TextureRect  # The mascot picture.
var _bubble: Control  # The speech bubble and its pointer, faded in and out together.
var _words: Label  # The words in the speech bubble.
var _typing: Tween  # The tween that types the current line.
var _fade: Tween  # The tween that fades the bubble in or out.
var _shown := false  # true while the bubble is showing.
var _mouth_time := 0.0  # Seconds of talking so far, for opening and closing the mouth.
var _quiet_time := 0.0  # Seconds since the line finished, for hiding the bubble.


# Runs when the mascot is made: remembers who it is and what it will say.
func _init(who: String, said: Array[String]) -> void:
	mascot_name = who  # Ana or Migo.
	lines = said  # The lines to say.


# Runs when the mascot is shown: builds the hidden bubble and the floating picture.
func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	add_theme_constant_override("separation", 2)  # The pointer nearly touches the mascot.
	mouse_filter = Control.MOUSE_FILTER_STOP  # Taps on the mascot come here.
	_frames = SpriteSheet.mascot(mascot_name.to_lower())  # This mascot's two pictures.
	add_child(_make_bubble())  # The speech bubble, hidden until a tap.
	var holder := Control.new()  # A plain box that keeps the mascot's place; the picture floats inside it.
	holder.custom_minimum_size = PICTURE_SIZE  # As big as the picture.
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	add_child(holder)  # Under the bubble.
	_picture = TextureRect.new()  # The mascot picture.
	_picture.texture = _frames[0]  # Smiling, mouth closed.
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Any size.
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Keep its shape.
	_picture.size = PICTURE_SIZE  # Its size on screen.
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	holder.add_child(_picture)  # Put it in its box.
	UiKit.bob(_picture, 10.0, 2.6, 0.3)  # Float gently, so learners can see it is alive and can be tapped (D-025).


# Makes the white speech bubble with a pointer down towards the mascot, hidden at first.
func _make_bubble() -> Control:
	_bubble = Control.new()  # Holds the bubble and its pointer.
	_bubble.custom_minimum_size = BUBBLE_SIZE  # Its size.
	_bubble.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	_bubble.modulate.a = 0.0  # Hidden until the mascot is tapped.
	var panel := PanelContainer.new()  # The bubble.
	var style := UiKit.box(Palette.WHITE, 44, 7)  # White, round and outlined.
	style.set_content_margin_all(20)  # Room inside.
	panel.add_theme_stylebox_override("panel", style)  # Use this look.
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the holder ...
	panel.offset_bottom = -TAIL_HEIGHT  # ... leaving room at the bottom for the pointer.
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	_bubble.add_child(panel)  # Add it.
	_words = UiKit.label("", 44, Palette.INK)  # The words, dark on white.
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Wrap between words.
	_words.custom_minimum_size.x = 100.0  # Let it wrap inside the bubble.
	panel.add_child(_words)  # Put the words in the bubble.
	var tail := Control.new()  # The pointer, drawn as a small triangle.
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	tail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Same area as the holder.
	tail.draw.connect(func() -> void: _draw_tail(tail))  # Draw the triangle when asked.
	_bubble.add_child(tail)  # Added after the bubble, so it covers the bubble's outline where they join.
	return _bubble  # Hand back the holder.


# Draws the bubble's pointer: a white triangle with a dark outline, pointing down at the mascot.
func _draw_tail(tail: Control) -> void:
	var middle := tail.size.x * 0.5  # Halfway across the bubble.
	var tip := Vector2(middle, tail.size.y - 2.0)  # The point, just above the mascot's head.
	var left := Vector2(middle - 24.0, tail.size.y - TAIL_HEIGHT - 12.0)  # Where the pointer meets the bubble, on the left ...
	var right := Vector2(middle + 24.0, tail.size.y - TAIL_HEIGHT - 12.0)  # ... and on the right.
	tail.draw_colored_polygon(PackedVector2Array([tip, left, right]), Palette.WHITE)  # The white pointer, over the bubble's edge.
	tail.draw_line(tip, left, Palette.INK, 7.0, true)  # Its left outline.
	tail.draw_line(tip, right, Palette.INK, 7.0, true)  # Its right outline.


# Shows the bubble and types a line into it, letter by letter.
func say(text: String) -> void:
	_words.text = text  # The words.
	_words.visible_ratio = 0.0  # None showing yet.
	if _typing != null and _typing.is_valid():  # An older line is still typing ...
		_typing.kill()  # ... so stop it.
	_typing = create_tween()  # A new typing tween.
	_typing.tween_property(_words, "visible_ratio", 1.0, maxf(text.length() / MascotLines.LETTERS_PER_SECOND, 0.1))  # Show the letters over time.
	_fade_bubble(1.0)  # Show the bubble.
	_shown = true  # It is showing.
	_mouth_time = 0.0  # Start talking.
	_quiet_time = 0.0  # Not quiet yet.


# Returns true while the current line is still being typed.
func is_talking() -> bool:
	return _shown and _words.visible_ratio < 1.0  # The bubble shows and some letters are still hidden.


# Returns true while the speech bubble is showing.
func is_bubble_shown() -> bool:
	return _shown  # Showing, or fading in.


# Says the next line, going back to the greeting after the last one. Called on each tap.
func next_line() -> void:
	line_index = (line_index + 1) % lines.size()  # The next line, round and round.
	say(lines[line_index])  # Say it.


# Fades the bubble in (1.0) or out (0.0) quickly.
func _fade_bubble(target: float) -> void:
	if _fade != null and _fade.is_valid():  # An older fade is still running ...
		_fade.kill()  # ... so stop it.
	_fade = create_tween()  # A new fade.
	_fade.tween_property(_bubble, "modulate:a", target, 0.2)  # Fade in or out.


# Runs every frame: opens and closes the mouth while talking; a few seconds after the line is
# finished, the bubble fades away.
func _process(delta: float) -> void:
	if is_talking():  # Typing a line ...
		_mouth_time += delta  # ... count talking time,
		var open := int(_mouth_time / MascotLines.MOUTH_SECONDS) % 2 == 1  # ... closed, then open, then closed ...
		_picture.texture = _frames[1 if open else 0]  # ... show the mouth.
		return  # Nothing else while talking.
	_picture.texture = _frames[0]  # Quiet: smile with the mouth closed.
	if _shown:  # The bubble still shows ...
		_quiet_time += delta  # ... count the quiet time,
		if _quiet_time >= MascotLines.BUBBLE_SECONDS:  # ... and after a while,
			_shown = false  # ... it is no longer showing,
			_fade_bubble(0.0)  # ... and fades away.


# Runs when the mascot is tapped: says the next line.
func _gui_input(event: InputEvent) -> void:
	var tap := event as InputEventMouseButton  # Taps arrive as mouse clicks.
	if tap != null and tap.pressed and tap.button_index == MOUSE_BUTTON_LEFT:  # A new tap ...
		accept_event()  # ... is handled here,
		next_line()  # ... and the next line comes.
