# A talking student mascot (D-024, D-025, D-026): Ana or Migo, shown from head to toe under a speech
# bubble. When nobody taps, the mascot breathes and sways gently. Each tap types the next line into
# the bubble, letter by letter, while the mouth opens and closes and one arm waves hello. A few
# seconds after the line is finished, the bubble fades away, so the screen stays clean. There is no
# voice.
class_name Mascot  # Lets the Main menu and tests write Mascot.new("Ana", lines).
extends VBoxContainer  # The speech bubble on top, the mascot underneath.

## The parts of the mascot, in the order of the frames in its sprite sheet (D-026).
enum Part { BODY, ARM_LEFT, ARM_RIGHT, HEAD, HEAD_TALKING }

const PICTURE_SIZE := Vector2(300, 520)  # The whole mascot from head to toe, the size of one sheet frame (D-026).
const BUBBLE_SIZE := Vector2(780, 190)  # The speech bubble, including its pointer.
const TAIL_HEIGHT := 28.0  # How far the bubble's pointer sticks down towards the mascot.
const SHOULDER_LEFT := Vector2(78, 232)  # Where the left arm turns, at the top of its sleeve.
const SHOULDER_RIGHT := Vector2(222, 232)  # Where the right arm turns, at the top of its sleeve.
const FEET := Vector2(150, 510)  # Where the body sways and breathes from, between the shoes.
const SWAY_DEGREES := 1.5  # How far the body tilts each way when idle.
const SWAY_SECONDS := 3.2  # One full sway, left and right and back.
const BREATH_AMOUNT := 0.015  # How much taller the body grows when breathing in (1.5%).
const BREATH_SECONDS := 2.4  # One full breath, in and out.
const WAVE_UP := -2.45  # Arm angle when raised to wave (about 140 degrees, up and out).
const WAVE_SWING := 0.3  # How far the raised arm swings each way while waving.
const WAVE_SWINGS := 3  # How many times the hand swings back and forth.

var mascot_name: String  # "Ana" or "Migo".
var lines: Array[String] = []  # Everything the mascot says, in order.
var line_index := -1  # Which line is showing now (-1: none yet, so the first tap says the greeting).
var _frames: Array[Texture2D] = []  # The five parts, in Part order.
var _rig: Control  # Holds every part; it breathes and sways as one.
var _body: TextureRect  # Body and legs.
var _arm_left: TextureRect  # The arm on the left, which stays down.
var _arm_right: TextureRect  # The arm on the right, which waves.
var _head: TextureRect  # The head, smiling or talking.
var _bubble: Control  # The speech bubble and its pointer, faded in and out together.
var _words: Label  # The words in the speech bubble.
var _typing: Tween  # The tween that types the current line.
var _fade: Tween  # The tween that fades the bubble in or out.
var _wave: Tween  # The tween that waves the arm.
var _shown := false  # true while the bubble is showing.
var _mouth_time := 0.0  # Seconds of talking so far, for opening and closing the mouth.
var _quiet_time := 0.0  # Seconds since the line finished, for hiding the bubble.


# Runs when the mascot is made: remembers who it is and what it will say.
func _init(who: String, said: Array[String]) -> void:
	mascot_name = who  # Ana or Migo.
	lines = said  # The lines to say.


# Runs when the mascot is shown: builds the hidden bubble and the moving mascot.
func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER  # Centred up and down.
	add_theme_constant_override("separation", 2)  # The pointer nearly touches the mascot.
	mouse_filter = Control.MOUSE_FILTER_STOP  # Taps on the mascot come here.
	_frames = SpriteSheet.mascot(mascot_name.to_lower())  # This mascot's five parts.
	add_child(_make_bubble())  # The speech bubble, hidden until a tap.
	var holder := Control.new()  # A plain box that keeps the mascot's place; the parts move inside it.
	holder.custom_minimum_size = PICTURE_SIZE  # As big as the whole mascot.
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	add_child(holder)  # Under the bubble.
	_rig = Control.new()  # Holds every part.
	_rig.size = PICTURE_SIZE  # As big as the whole mascot.
	_rig.pivot_offset = FEET  # It sways and breathes from the feet, so the shoes stay on the ground.
	_rig.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	holder.add_child(_rig)  # Put it in its box.
	_body = _add_part(Part.BODY, Vector2.ZERO)  # Body and legs, at the back.
	_arm_left = _add_part(Part.ARM_LEFT, SHOULDER_LEFT)  # Left arm, over the side of the top.
	_arm_right = _add_part(Part.ARM_RIGHT, SHOULDER_RIGHT)  # Right arm, over the side of the top.
	_head = _add_part(Part.HEAD, Vector2.ZERO)  # Head, in front of everything.
	_start_idle()  # Breathe and sway while nobody taps (D-026).


# Adds one part of the mascot to the rig, at full size, turning around `pivot` when rotated.
# Every part is drawn at its own place on a whole-mascot frame, so all parts sit at (0, 0).
func _add_part(part: Part, pivot: Vector2) -> TextureRect:
	var picture := TextureRect.new()  # The part's picture.
	picture.texture = _frames[part]  # Its frame from the sheet.
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Any size.
	picture.size = PICTURE_SIZE  # As big as the whole mascot, so the parts line up.
	picture.pivot_offset = pivot  # Where it turns, for the arms.
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	_rig.add_child(picture)  # Later parts are drawn in front of earlier ones.
	return picture  # Hand it back.


# Starts the idle movement: the body tilts a little left and right, and grows a tiny bit taller and
# back, like breathing, forever (D-026). The two use different times, so the movement never looks
# like a simple repeat.
func _start_idle() -> void:
	var sway := create_tween().set_loops()  # Sway forever.
	sway.tween_property(_rig, "rotation", deg_to_rad(SWAY_DEGREES), SWAY_SECONDS / 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)  # Tilt one way ...
	sway.tween_property(_rig, "rotation", deg_to_rad(-SWAY_DEGREES), SWAY_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # ... over to the other way ...
	sway.tween_property(_rig, "rotation", 0.0, SWAY_SECONDS / 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)  # ... and back to straight.
	var breath := create_tween().set_loops()  # Breathe forever.
	breath.tween_property(_rig, "scale:y", 1.0 + BREATH_AMOUNT, BREATH_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # Breathe in: a little taller.
	breath.tween_property(_rig, "scale:y", 1.0, BREATH_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # Breathe out.


# Waves hello with the right arm: up, a few swings, then back down to the side (D-026).
func wave() -> void:
	if _wave != null and _wave.is_valid():  # Still waving from the last tap ...
		_wave.kill()  # ... so start again from where the arm is.
	_wave = create_tween()  # A new wave.
	_wave.tween_property(_arm_right, "rotation", WAVE_UP, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)  # Raise the arm.
	for i in range(WAVE_SWINGS):  # A few swings ...
		_wave.tween_property(_arm_right, "rotation", WAVE_UP + WAVE_SWING, 0.16).set_trans(Tween.TRANS_SINE)  # ... one way ...
		_wave.tween_property(_arm_right, "rotation", WAVE_UP - WAVE_SWING, 0.16).set_trans(Tween.TRANS_SINE)  # ... and the other.
	_wave.tween_property(_arm_right, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # Lower the arm to the side.


# Returns true while the arm is waving.
func is_waving() -> bool:
	return _wave != null and _wave.is_running()  # A wave is under way.


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


# Says the next line, going back to the greeting after the last one, and waves. Called on each tap.
func next_line() -> void:
	line_index = (line_index + 1) % lines.size()  # The next line, round and round.
	say(lines[line_index])  # Say it.
	wave()  # Wave hello while talking (D-026).


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
		_head.texture = _frames[Part.HEAD_TALKING if open else Part.HEAD]  # ... show the mouth.
		return  # Nothing else while talking.
	_head.texture = _frames[Part.HEAD]  # Quiet: smile with the mouth closed.
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
