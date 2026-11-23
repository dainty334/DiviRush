# Tests for the talking student mascots, Ana and Migo (D-024): what they say, how they talk,
# and how they take turns on the Main menu.
extends GutTest  # GUT gives this script its assert_* checks.

const EASY := Difficulty.Kind.EASY  # Short name for Easy.
const MAIN_MENU := "res://scenes/screens/main_menu.tscn"  # The Main menu scene.

var _real_progress: Progress  # The game's own progress, put back after each test.
var _real_records: Records  # The game's own records, put back after each test.


# Runs before every test: fresh progress and records in memory only.
func before_each() -> void:
	_real_progress = Save.progress  # Keep the game's progress safe.
	_real_records = Save.records  # Keep the game's records safe.
	Save.progress = Progress.new()  # Fresh progress.
	Save.records = Records.new()  # Fresh records.


# Runs after every test: puts the game's own progress and records back.
func after_each() -> void:
	Save.progress = _real_progress  # Back to the real progress.
	Save.records = _real_records  # Back to the real records.


# A new learner: the mascot says its name, invites them to start, and gives division tips.
func test_lines_for_a_new_learner() -> void:
	var lines := MascotLines.lines_for("Ana", Save.progress, Save.records)  # What Ana says.
	assert_eq(lines[0], "Hi! I'm Ana. Let's divide!")  # A greeting with her name.
	assert_has(lines, "Tap Play to start your first Level!")  # No Stars yet: an invitation.
	assert_has(lines, "Try Episode 1 Easy Level 1 next!")  # The first open Level.
	assert_has(lines, "Next Trophy: First Star. Earn your first Star!")  # The first Trophy to aim for.
	for tip: String in MascotLines.TIPS:  # Every division tip ...
		assert_has(lines, tip)  # ... is said too.


# With some progress, the lines count the Stars and point to the next Level and Trophy.
func test_lines_follow_the_progress() -> void:
	Save.progress.record(1, EASY, 1, 3, 250, 50.0)  # Level 1: 3 Stars.
	Save.progress.record(1, EASY, 2, 2, 200, 60.0)  # Level 2: 2 Stars.
	Trophies.award(Save.progress, Save.records)  # "First Star" and "Perfect 10" earned.
	var lines := MascotLines.lines_for("Migo", Save.progress, Save.records)  # What Migo says.
	assert_eq(lines[0], "Hi! I'm Migo. Let's divide!")  # A greeting with his name.
	assert_has(lines, "You have 5 Stars. Great work!")  # 3 + 2 Stars.
	assert_has(lines, "Try Episode 1 Easy Level 3 next!")  # The next open Level not yet passed.
	assert_has(lines, "Next Trophy: On a Roll. Get 5 right in a row!")  # The next Trophy not yet earned.


# Returns a tap with the left button (a finger on a phone), going down.
func _tap() -> InputEventMouseButton:
	var tap := InputEventMouseButton.new()  # A tap ...
	tap.button_index = MOUSE_BUTTON_LEFT  # ... with the left button,
	tap.pressed = true  # ... going down.
	return tap  # Hand it back.


# The mascot is quiet until tapped (D-025); then it types the line letter by letter with its mouth
# moving, and smiles quietly when the line is finished.
func test_mascot_talks_only_when_tapped() -> void:
	var mascot := Mascot.new("Ana", ["Hello there!"] as Array[String])  # Ana with one line.
	add_child_autofree(mascot)  # In the tree.
	var frames := SpriteSheet.mascot("ana")  # Her five parts: body, two arms, head smiling, head talking.
	assert_false(mascot.is_bubble_shown())  # No speech bubble at first ...
	assert_false(mascot.is_talking())  # ... and no talking.
	mascot._gui_input(_tap())  # She is tapped.
	assert_true(mascot.is_bubble_shown())  # The bubble shows ...
	assert_true(mascot.is_talking())  # ... and she starts typing.
	assert_eq(mascot._words.text, "Hello there!")  # The first line.
	mascot._process(MascotLines.MOUTH_SECONDS + 0.01)  # A moment passes ...
	assert_eq(mascot._head.texture, frames[Mascot.Part.HEAD_TALKING])  # ... and her mouth is open.
	await wait_seconds(1.0)  # The line finishes typing.
	mascot._process(0.01)  # The next frame.
	assert_false(mascot.is_talking())  # She has finished the line ...
	assert_eq(mascot._head.texture, frames[Mascot.Part.HEAD])  # ... and smiles with her mouth closed.


# The mascot is shown from head to toe (D-026): a body with legs, two arms and a head, about 520
# pixels tall, so the face stays as big as before.
func test_mascot_is_full_body() -> void:
	var mascot := Mascot.new("Migo", ["Hi!"] as Array[String])  # Migo with one line.
	add_child_autofree(mascot)  # In the tree.
	var frames := SpriteSheet.mascot("migo")  # His five parts.
	assert_eq(frames.size(), 5)  # Body, left arm, right arm, head smiling, head talking.
	assert_eq(Mascot.PICTURE_SIZE, Vector2(300, 520))  # Head to toe.
	assert_eq(mascot._body.texture, frames[Mascot.Part.BODY])  # His body and legs ...
	assert_eq(mascot._arm_left.texture, frames[Mascot.Part.ARM_LEFT])  # ... his left arm ...
	assert_eq(mascot._arm_right.texture, frames[Mascot.Part.ARM_RIGHT])  # ... his right arm ...
	assert_eq(mascot._head.texture, frames[Mascot.Part.HEAD])  # ... and his smiling head.


# A tap makes the mascot wave hello with one arm, which then drops back to the side (D-026).
func test_tap_waves_hello() -> void:
	var mascot := Mascot.new("Ana", ["Hello there!"] as Array[String])  # Ana with one line.
	add_child_autofree(mascot)  # In the tree.
	assert_false(mascot.is_waving())  # Not waving before the tap.
	assert_almost_eq(mascot._arm_right.rotation, 0.0, 0.001)  # Her arm hangs down.
	mascot._gui_input(_tap())  # She is tapped.
	assert_true(mascot.is_waving())  # She starts waving ...
	await wait_seconds(0.4)  # ... and a moment later
	assert_lt(mascot._arm_right.rotation, -1.5)  # ... her arm is raised high.
	await wait_seconds(2.0)  # The wave ends.
	assert_false(mascot.is_waving())  # Not waving any more ...
	assert_almost_eq(mascot._arm_right.rotation, 0.0, 0.001)  # ... and her arm is back down.


# When nobody taps, the mascot breathes and sways gently (D-026).
func test_idle_mascot_breathes_and_sways() -> void:
	var mascot := Mascot.new("Migo", ["Hi!"] as Array[String])  # Migo with one line.
	add_child_autofree(mascot)  # In the tree.
	await wait_seconds(0.8)  # Some time passes with no tap.
	assert_ne(mascot._rig.rotation, 0.0)  # He tilts a little ...
	assert_gt(mascot._rig.scale.y, 1.0)  # ... and rises as he breathes in.


# Each tap brings the next line; a few seconds after a line is finished the bubble goes away,
# and no new line comes by itself (D-025).
func test_each_tap_brings_the_next_line_then_the_bubble_goes() -> void:
	var said: Array[String] = ["One.", "Two.", "Three."]  # Three short lines.
	var mascot := Mascot.new("Migo", said)  # Migo with them.
	add_child_autofree(mascot)  # In the tree.
	mascot._gui_input(_tap())  # First tap ...
	assert_eq(mascot._words.text, "One.")  # ... the first line.
	mascot._gui_input(_tap())  # Second tap ...
	assert_eq(mascot._words.text, "Two.")  # ... the next line.
	mascot._words.visible_ratio = 1.0  # The line has finished typing.
	mascot._process(MascotLines.BUBBLE_SECONDS + 0.1)  # A few quiet seconds pass.
	assert_false(mascot.is_bubble_shown())  # The bubble has gone ...
	assert_eq(mascot._words.text, "Two.")  # ... and no new line came by itself.


# Ana and Migo take turns: each time the Main menu opens, the other one is there.
func test_mascots_take_turns_on_the_main_menu() -> void:
	var first: Node = load(MAIN_MENU).instantiate()  # The Main menu opens ...
	add_child_autofree(first)  # ... once,
	var second: Node = load(MAIN_MENU).instantiate()  # ... and again.
	add_child_autofree(second)  # In the tree.
	assert_has(MascotLines.NAMES, first._mascot.mascot_name)  # Ana or Migo ...
	assert_ne(first._mascot.mascot_name, second._mascot.mascot_name)  # ... and the other one next time.
