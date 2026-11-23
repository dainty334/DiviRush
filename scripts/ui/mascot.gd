# A talking student mascot (D-024): Ana or Migo, with a speech bubble beside them. Each line is
# typed into the bubble letter by letter while the mouth opens and closes; a new line comes after a
# few quiet seconds, or at once when the mascot or the bubble is tapped. There is no voice.
class_name Mascot  # Lets the Main menu and tests write Mascot.new("Ana", lines).
extends HBoxContainer  # The mascot on the left, the speech bubble on the right.

const PICTURE_SIZE := Vector2(290, 329)  # The mascot picture, in the sheet's 300 x 340 shape.
const TAIL_WIDTH := 30.0  # How far the bubble's pointer sticks out towards the mascot.

var mascot_name: String  # "Ana" or "Migo".
var lines: Array[String] = []  # Everything the mascot says, in order.
var line_index := 0  # Which line is showing now.
var _frames: Array[Texture2D] = []  # Mouth closed (0) and mouth open (1).
var _picture: TextureRect  # The mascot picture.
var _words: Label  # The words in the speech bubble.
var _typing: Tween  # The tween that types the current line.
var _mouth_time := 0.0  # Seconds of talking so far, for opening and closing the mouth.
var _quiet_time := 0.0  # Seconds since the line finished, for moving to the next line.


# Runs when the mascot is made: remembers who it is and what it will say.
func _init(who: String, said: Array[String]) -> void:
	mascot_name = who  # Ana or Migo.
	lines = said  # The lines to say.


# Runs when the mascot is shown: builds the picture and the bubble, then says the first line.
func _ready() -> void:
	add_theme_constant_override("separation", 0)  # The bubble's pointer touches the mascot.
	mouse_filter = Control.MOUSE_FILTER_STOP  # Taps on the mascot or the bubble come here.
	_frames = SpriteSheet.mascot(mascot_name.to_lower())  # This mascot's two pictures.
	_picture = TextureRect.new()  # The mascot picture.
	_picture.texture = _frames[0]  # Smiling, mouth closed.
	_picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Any size.
	_picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Keep its shape.
	_picture.custom_minimum_size = PICTURE_SIZE  # Its size on screen.
	_picture.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	add_child(_picture)  # Show it.
	add_child(_make_bubble())  # The speech bubble beside it.
	say(lines[0])  # Start with the first line (the greeting).


# Makes the white speech bubble with a pointer towards the mascot, and the label for the words.
func _make_bubble() -> Control:
	var holder := Control.new()  # Holds the pointer and the bubble.
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the rest of the row.
	holder.custom_minimum_size = Vector2(0, 250)  # Tall enough for three lines of words.
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	var bubble := PanelContainer.new()  # The bubble.
	var style := UiKit.box(Palette.WHITE, 44, 7)  # White, round and outlined.
	style.set_content_margin_all(22)  # Room inside.
	bubble.add_theme_stylebox_override("panel", style)  # Use this look.
	bubble.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the holder ...
	bubble.offset_left = TAIL_WIDTH  # ... leaving room on the left for the pointer.
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	holder.add_child(bubble)  # Add it.
	_words = UiKit.label("", 42, Palette.INK)  # The words, dark on white.
	_words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # Wrap between words.
	_words.custom_minimum_size.x = 100.0  # Let it wrap inside the bubble.
	bubble.add_child(_words)  # Put the words in the bubble.
	var tail := Control.new()  # The pointer, drawn as a small triangle.
	tail.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	tail.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Same area as the holder.
	tail.draw.connect(func() -> void: _draw_tail(tail))  # Draw the triangle when asked.
	holder.add_child(tail)  # Added after the bubble, so it covers the bubble's outline where they join.
	return holder  # Hand back the holder.


# Draws the bubble's pointer: a white triangle with a dark outline, pointing left at the mascot.
func _draw_tail(tail: Control) -> void:
	var middle := tail.size.y * 0.5  # Halfway down the bubble.
	var tip := Vector2(2.0, middle)  # The point, next to the mascot.
	var top := Vector2(TAIL_WIDTH + 12.0, middle - 22.0)  # Where the pointer meets the bubble, above ...
	var bottom := Vector2(TAIL_WIDTH + 12.0, middle + 22.0)  # ... and below.
	tail.draw_colored_polygon(PackedVector2Array([tip, top, bottom]), Palette.WHITE)  # The white pointer, over the bubble's edge.
	tail.draw_line(tip, top, Palette.INK, 7.0, true)  # Its top outline.
	tail.draw_line(tip, bottom, Palette.INK, 7.0, true)  # Its bottom outline.


# Types a line into the speech bubble, letter by letter.
func say(text: String) -> void:
	_words.text = text  # The words.
	_words.visible_ratio = 0.0  # None showing yet.
	if _typing != null and _typing.is_valid():  # An older line is still typing ...
		_typing.kill()  # ... so stop it.
	_typing = create_tween()  # A new typing tween.
	_typing.tween_property(_words, "visible_ratio", 1.0, maxf(text.length() / MascotLines.LETTERS_PER_SECOND, 0.1))  # Show the letters over time.
	_mouth_time = 0.0  # Start talking.
	_quiet_time = 0.0  # Not quiet yet.


# Returns true while the current line is still being typed.
func is_talking() -> bool:
	return _words.visible_ratio < 1.0  # Some letters are still hidden.


# Moves to the next line, going back to the greeting after the last one.
func next_line() -> void:
	line_index = (line_index + 1) % lines.size()  # The next line, round and round.
	say(lines[line_index])  # Say it.


# Runs every frame: opens and closes the mouth while talking; after a quiet while, says the next line.
func _process(delta: float) -> void:
	if is_talking():  # Typing a line ...
		_mouth_time += delta  # ... count talking time,
		var open := int(_mouth_time / MascotLines.MOUTH_SECONDS) % 2 == 1  # ... closed, then open, then closed ...
		_picture.texture = _frames[1 if open else 0]  # ... show the mouth.
	else:  # The line is finished ...
		_picture.texture = _frames[0]  # ... smile with the mouth closed,
		_quiet_time += delta  # ... count the quiet time,
		if _quiet_time >= MascotLines.LINE_SECONDS:  # ... and after a while,
			next_line()  # ... say the next line.


# Runs when the mascot or its bubble is tapped: shows the next line at once.
func _gui_input(event: InputEvent) -> void:
	var tap := event as InputEventMouseButton  # Taps arrive as mouse clicks.
	if tap != null and tap.pressed and tap.button_index == MOUSE_BUTTON_LEFT:  # A new tap ...
		accept_event()  # ... is handled here,
		next_line()  # ... and the next line comes.
