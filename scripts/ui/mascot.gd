# A talking student mascot (D-024 to D-027): Ana or Migo, shown big from head to toe. When the Main
# menu opens, the mascot drops in with a little bounce. When nobody taps, it breathes, sways,
# swings its arms a little and blinks. Each tap types the next line into a speech bubble that
# floats above the head, letter by letter, while the mouth opens and closes, the head nods, the
# eyebrows lift and one arm waves hello. A few seconds after the line is finished, the bubble
# fades away, so the screen stays clean. There is no voice.
class_name Mascot  # Lets the Main menu and tests write Mascot.new("Ana", lines).
extends Control  # A plain box: the mascot fills it, and the bubble floats above it.

## The parts of the mascot, in the order of the frames in its sprite sheet (D-027).
enum Part { BODY, ARM_LEFT, ARM_RIGHT, HEAD, EYES_OPEN, EYES_CLOSED, BROWS, MOUTH, MOUTH_TALKING }

const SCALE := 1.5  # The mascot is drawn 1.5 times bigger than its 300 x 520 plan (D-027).
const PICTURE_SIZE := Vector2(300, 520) * SCALE  # The whole mascot from head to toe, the size of one sheet frame.
const BUBBLE_SIZE := Vector2(780, 190)  # The speech bubble, including its pointer.
const TAIL_HEIGHT := 28.0  # How far the bubble's pointer sticks down towards the mascot.
const HEAD_TOP := 36.0 * SCALE  # Where the top of the hair is, so the bubble's pointer can touch it.
const SHOULDER_LEFT := Vector2(68, 232) * SCALE  # Where the left arm turns, at the top of its sleeve.
const SHOULDER_RIGHT := Vector2(232, 232) * SCALE  # Where the right arm turns, at the top of its sleeve.
const NECK := Vector2(150, 205) * SCALE  # Where the head nods and tilts from.
const FEET := Vector2(150, 510) * SCALE  # Where the body sways and breathes from, between the shoes.
const SWAY_DEGREES := 1.5  # How far the body tilts each way when idle.
const SWAY_SECONDS := 3.2  # One full sway, left and right and back.
const BREATH_AMOUNT := 0.015  # How much taller the body grows when breathing in (1.5%).
const BREATH_SECONDS := 2.4  # One full breath, in and out.
const ARM_SWING_DEGREES := 4.0  # How far each arm swings when idle (D-027).
const ARM_SWING_SECONDS := 2.8  # One full arm swing, forward and back.
const WAVE_UP := -2.45  # Arm angle when raised to wave (about 140 degrees, up and out).
const WAVE_SWING := 0.3  # How far the raised arm swings each way while waving.
const WAVE_SWINGS := 3  # How many times the hand swings back and forth.
const BLINK_SECONDS := 0.12  # How long the eyes stay closed in a blink (D-027).
const BLINK_GAP_MIN := 2.0  # The shortest wait between blinks, in seconds.
const BLINK_GAP_MAX := 5.0  # The longest wait between blinks, in seconds.
const NOD_DEGREES := 3.0  # How far the head tilts each way while talking (D-027).
const NOD_SPEED := 7.0  # How fast the head nods while talking.
const BROW_LIFT := 7.0 * SCALE  # How far the eyebrows lift while talking.
const SETTLE_SPEED := 10.0  # How fast the head and eyebrows settle back when quiet.
const DROP_HEIGHT := 260.0  # How far above its place the mascot starts when it drops in (D-027).
const DROP_SECONDS := 0.8  # How long the drop takes, bounce included.

var mascot_name: String  # "Ana" or "Migo".
var lines: Array[String] = []  # Everything the mascot says, in order.
var line_index := -1  # Which line is showing now (-1: none yet, so the first tap says the greeting).
var _frames: Array[Texture2D] = []  # The nine parts, in Part order.
var _rig: Control  # Holds every part; it drops in, breathes and sways as one.
var _body: TextureRect  # Backpack, body and legs.
var _arm_left: TextureRect  # The arm on the left, which swings.
var _arm_right: TextureRect  # The arm on the right, which swings and waves.
var _head_rig: Control  # Holds the head and its face; it nods and tilts while talking.
var _head: TextureRect  # Hair, ears, face and cheeks.
var _eyes: TextureRect  # The eyes, open or closed.
var _brows: TextureRect  # The eyebrows, which lift while talking.
var _mouth: TextureRect  # The mouth, smiling or talking.
var _bubble: Control  # The speech bubble and its pointer, faded in and out together.
var _words: Label  # The words in the speech bubble.
var _typing: Tween  # The tween that types the current line.
var _fade: Tween  # The tween that fades the bubble in or out.
var _wave: Tween  # The tween that waves the arm.
var _swing_right: Tween  # The idle swing of the right arm, paused while it waves.
var _shown := false  # true while the bubble is showing.
var _mouth_time := 0.0  # Seconds of talking so far, for the mouth and the nod.
var _quiet_time := 0.0  # Seconds since the line finished, for hiding the bubble.
var _next_blink := 3.0  # Seconds until the next blink.
var _blink_left := 0.0  # Seconds the eyes still stay closed (0: open).


# Runs when the mascot is made: remembers who it is and what it will say.
func _init(who: String, said: Array[String]) -> void:
	mascot_name = who  # Ana or Migo.
	lines = said  # The lines to say.


# Runs when the mascot is shown: builds the moving mascot and the hidden bubble above it.
func _ready() -> void:
	custom_minimum_size = PICTURE_SIZE  # Takes the room of the whole mascot, and no more (D-027).
	mouse_filter = Control.MOUSE_FILTER_STOP  # Taps on the mascot come here.
	_frames = SpriteSheet.mascot(mascot_name.to_lower())  # This mascot's nine parts.
	_rig = _add_box(self, FEET)  # Holds every part; sways and breathes from the feet.
	_body = _add_part(_rig, Part.BODY, Vector2.ZERO)  # Backpack, body and legs, at the back.
	_arm_left = _add_part(_rig, Part.ARM_LEFT, SHOULDER_LEFT)  # Left arm, over the side of the top.
	_arm_right = _add_part(_rig, Part.ARM_RIGHT, SHOULDER_RIGHT)  # Right arm, over the side of the top.
	_head_rig = _add_box(_rig, NECK)  # Holds the head; nods from the neck.
	_head = _add_part(_head_rig, Part.HEAD, Vector2.ZERO)  # Hair, ears, face and cheeks.
	_eyes = _add_part(_head_rig, Part.EYES_OPEN, Vector2.ZERO)  # Open eyes.
	_brows = _add_part(_head_rig, Part.BROWS, Vector2.ZERO)  # Eyebrows.
	_mouth = _add_part(_head_rig, Part.MOUTH, Vector2.ZERO)  # Smile.
	add_child(_make_bubble())  # The speech bubble, hidden until a tap, in front of the mascot.
	_next_blink = randf_range(BLINK_GAP_MIN, BLINK_GAP_MAX)  # When the first blink comes.
	_drop_in()  # Drop in with a bounce (D-027).
	_start_idle()  # Breathe, sway and swing the arms while nobody taps (D-026, D-027).


# Adds a plain box as big as the whole mascot to `parent`, turning around `pivot` when rotated.
func _add_box(parent: Control, pivot: Vector2) -> Control:
	var box := Control.new()  # A plain box for moving parts together.
	box.size = PICTURE_SIZE  # As big as the whole mascot.
	box.pivot_offset = pivot  # Where it turns and grows from.
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	parent.add_child(box)  # Put it in place.
	return box  # Hand it back.


# Adds one part of the mascot to `parent`, at full size, turning around `pivot` when rotated.
# Every part is drawn at its own place on a whole-mascot frame, so all parts sit at (0, 0).
func _add_part(parent: Control, part: Part, pivot: Vector2) -> TextureRect:
	var picture := TextureRect.new()  # The part's picture.
	picture.texture = _frames[part]  # Its frame from the sheet.
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Any size.
	picture.size = PICTURE_SIZE  # As big as the whole mascot, so the parts line up.
	picture.pivot_offset = pivot  # Where it turns, for the arms.
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the mascot as a whole.
	parent.add_child(picture)  # Later parts are drawn in front of earlier ones.
	return picture  # Hand it back.


# Drops the mascot in from above its place with a little bounce, fading in on the way (D-027).
func _drop_in() -> void:
	_rig.position.y = -DROP_HEIGHT  # Start above its place ...
	_rig.modulate.a = 0.0  # ... and unseen.
	var drop := create_tween().set_parallel()  # Fall and fade in at the same time.
	drop.tween_property(_rig, "position:y", 0.0, DROP_SECONDS).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)  # Fall and bounce.
	drop.tween_property(_rig, "modulate:a", 1.0, 0.2)  # Fade in quickly.


# Starts the idle movement: the body tilts a little left and right and grows a tiny bit taller and
# back, like breathing, and the arms swing gently, forever (D-026, D-027). Each uses its own time,
# so the movement never looks like a simple repeat.
func _start_idle() -> void:
	var sway := create_tween().set_loops()  # Sway forever.
	sway.tween_property(_rig, "rotation", deg_to_rad(SWAY_DEGREES), SWAY_SECONDS / 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)  # Tilt one way ...
	sway.tween_property(_rig, "rotation", deg_to_rad(-SWAY_DEGREES), SWAY_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # ... over to the other way ...
	sway.tween_property(_rig, "rotation", 0.0, SWAY_SECONDS / 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)  # ... and back to straight.
	var breath := create_tween().set_loops()  # Breathe forever.
	breath.tween_property(_rig, "scale:y", 1.0 + BREATH_AMOUNT, BREATH_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # Breathe in: a little taller.
	breath.tween_property(_rig, "scale:y", 1.0, BREATH_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # Breathe out.
	_swing_arm(_arm_left, 1.0)  # The left arm swings ...
	_swing_right = _swing_arm(_arm_right, -1.0)  # ... and the right arm swings the other way, like walking on the spot.


# Swings `arm` gently forward and back forever, starting in `direction` (1 or -1). Returns its tween.
func _swing_arm(arm: TextureRect, direction: float) -> Tween:
	var angle := deg_to_rad(ARM_SWING_DEGREES) * direction  # How far it swings, and which way first.
	var swing := create_tween().set_loops()  # Swing forever.
	swing.tween_property(arm, "rotation", angle, ARM_SWING_SECONDS / 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)  # Swing one way ...
	swing.tween_property(arm, "rotation", -angle, ARM_SWING_SECONDS / 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # ... over to the other way ...
	swing.tween_property(arm, "rotation", 0.0, ARM_SWING_SECONDS / 4.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)  # ... and back down.
	return swing  # Hand it back.


# Waves hello with the right arm: up, a few swings, then back down to its idle swing (D-026).
func wave() -> void:
	if _wave != null and _wave.is_valid():  # Still waving from the last tap ...
		_wave.kill()  # ... so start again from where the arm is.
	_swing_right.pause()  # The idle swing stops while the arm waves.
	_wave = create_tween()  # A new wave.
	_wave.tween_property(_arm_right, "rotation", WAVE_UP, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)  # Raise the arm.
	for i in range(WAVE_SWINGS):  # A few swings ...
		_wave.tween_property(_arm_right, "rotation", WAVE_UP + WAVE_SWING, 0.16).set_trans(Tween.TRANS_SINE)  # ... one way ...
		_wave.tween_property(_arm_right, "rotation", WAVE_UP - WAVE_SWING, 0.16).set_trans(Tween.TRANS_SINE)  # ... and the other.
	_wave.tween_property(_arm_right, "rotation", 0.0, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)  # Lower the arm to the side.
	_wave.tween_callback(_swing_right.play)  # Then swing gently again.


# Returns true while the arm is waving.
func is_waving() -> bool:
	return _wave != null and _wave.is_running()  # A wave is under way.


# Makes the white speech bubble, hidden at first, floating over the sky above the head with its
# pointer touching the hair, so it needs no room of its own (D-027).
func _make_bubble() -> Control:
	_bubble = Control.new()  # Holds the bubble and its pointer.
	_bubble.size = BUBBLE_SIZE  # Its size.
	_bubble.position = Vector2((PICTURE_SIZE.x - BUBBLE_SIZE.x) / 2.0, HEAD_TOP - BUBBLE_SIZE.y)  # Centred over the mascot, just above the hair.
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


# Runs every frame: blinks now and then; while talking, moves the mouth, nods the head and lifts
# the eyebrows; when quiet, settles the head and eyebrows back, and a few seconds after the line is
# finished, the bubble fades away.
func _process(delta: float) -> void:
	_update_blink(delta)  # Blink now and then, talking or not (D-027).
	if is_talking():  # Typing a line ...
		_mouth_time += delta  # ... count talking time,
		var open := int(_mouth_time / MascotLines.MOUTH_SECONDS) % 2 == 1  # ... closed, then open, then closed ...
		_mouth.texture = _frames[Part.MOUTH_TALKING if open else Part.MOUTH]  # ... show the mouth,
		_head_rig.rotation = sin(_mouth_time * NOD_SPEED) * deg_to_rad(NOD_DEGREES)  # ... tilt the head from side to side,
		_head_rig.position.y = absf(sin(_mouth_time * NOD_SPEED)) * 3.0 * SCALE  # ... nod it a little,
		_brows.position.y = -BROW_LIFT  # ... and lift the eyebrows (D-027).
		return  # Nothing else while talking.
	_mouth.texture = _frames[Part.MOUTH]  # Quiet: smile with the mouth closed.
	var settle := minf(delta * SETTLE_SPEED, 1.0)  # How much to settle back this frame.
	_head_rig.rotation = lerpf(_head_rig.rotation, 0.0, settle)  # The head straightens ...
	_head_rig.position.y = lerpf(_head_rig.position.y, 0.0, settle)  # ... stops nodding ...
	_brows.position.y = lerpf(_brows.position.y, 0.0, settle)  # ... and the eyebrows come back down.
	if _shown:  # The bubble still shows ...
		_quiet_time += delta  # ... count the quiet time,
		if _quiet_time >= MascotLines.BUBBLE_SECONDS:  # ... and after a while,
			_shown = false  # ... it is no longer showing,
			_fade_bubble(0.0)  # ... and fades away.


# Closes the eyes for a moment every 2 to 5 seconds, at random, so the blinks do not look timed (D-027).
func _update_blink(delta: float) -> void:
	if _blink_left > 0.0:  # The eyes are closed ...
		_blink_left -= delta  # ... count down,
		if _blink_left <= 0.0:  # ... and when the moment is over,
			_eyes.texture = _frames[Part.EYES_OPEN]  # ... open them again.
		return  # Nothing else while blinking.
	_next_blink -= delta  # Count down to the next blink.
	if _next_blink <= 0.0:  # Time to blink ...
		_eyes.texture = _frames[Part.EYES_CLOSED]  # ... close the eyes,
		_blink_left = BLINK_SECONDS  # ... for a moment,
		_next_blink = randf_range(BLINK_GAP_MIN, BLINK_GAP_MAX)  # ... and pick when the next blink comes.


# Runs when the mascot is tapped: says the next line.
func _gui_input(event: InputEvent) -> void:
	var tap := event as InputEventMouseButton  # Taps arrive as mouse clicks.
	if tap != null and tap.pressed and tap.button_index == MOUSE_BUTTON_LEFT:  # A new tap ...
		accept_event()  # ... is handled here,
		next_line()  # ... and the next line comes.
