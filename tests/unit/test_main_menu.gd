# Tests for the Main menu look (D-017): four straight, lined-up buttons with drawn icons, a breathing
# Play button, the waving DIVIRUSH title, the tagline and the total-Stars pill.
extends GutTest  # GUT gives this script its assert_* checks.

const MAIN_MENU := "res://scenes/screens/main_menu.tscn"  # The Main menu scene.

var screen: Node  # A fresh Main menu for each test.
var _real_progress: Progress  # The game's own progress, put back after each test.


# Runs before every test: gives the learner 3 + 2 Stars in memory, then opens a new Main menu.
func before_each() -> void:
	_real_progress = Save.progress  # Keep the game's progress safe.
	Save.progress = Progress.new()  # Fresh progress in memory only.
	Save.progress.record(1, Difficulty.Kind.EASY, 1, 3, 250, 50.0)  # Episode 1 Easy Level 1: 3 Stars.
	Save.progress.record(2, Difficulty.Kind.EASY, 1, 2, 200, 60.0)  # Episode 2 Easy Level 1: 2 Stars.
	screen = load(MAIN_MENU).instantiate()  # A new Main menu.
	add_child_autofree(screen)  # In the tree (this builds it), freed after the test.


# Runs after every test: puts the game's own progress back.
func after_each() -> void:
	Save.progress = _real_progress  # Back to the real progress.


# Returns the words on the Main menu buttons, top to bottom.
func _button_words() -> Array[String]:
	var words: Array[String] = []  # The list to fill.
	for button: Button in screen._buttons:  # Each button ...
		words.append(button.text)  # ... adds its words.
	return words  # Hand back the list.


# The four buttons keep their order and words (D-008).
func test_four_buttons_in_order() -> void:
	assert_eq(_button_words(), ["Play", "How to Play", "Settings", "Exit"] as Array[String])  # The four choices.


# Each button shows its own drawn icon: play arrow, question mark, gear, door (D-017).
func test_every_button_has_its_icon() -> void:
	var icons := SpriteSheet.icons()  # Every icon frame.
	var expected := [UiKit.Icon.PLAY, UiKit.Icon.HELP, UiKit.Icon.GEAR, UiKit.Icon.EXIT]  # One icon per button, in order.
	for i in range(4):  # Each button ...
		var pictures: Array[Node] = screen._buttons[i].find_children("*", "TextureRect", true, false)  # ... its pictures,
		assert_eq(pictures.size(), 1, _button_words()[i])  # ... exactly one icon,
		assert_eq((pictures[0] as TextureRect).texture, icons[expected[i]], _button_words()[i])  # ... the right one.


# Once they have popped in, the buttons stand straight (no rocking) and share one width, so they line up.
func test_buttons_stand_straight_and_line_up() -> void:
	await wait_seconds(1.3)  # Let the pop-in finish; the old rocking would have tilted them by now.
	for button: Button in screen._buttons:  # Each button ...
		assert_almost_eq(button.rotation, 0.0, 0.0001, button.text)  # ... stands straight,
		assert_eq(button.size.x, screen._buttons[0].size.x, button.text)  # ... and is as wide as Play.
	for i in range(1, 4):  # How to Play, Settings and Exit ...
		assert_eq(screen._buttons[i].scale, Vector2.ONE, screen._buttons[i].text)  # ... stay still at full size.


# Only Play moves on its own: it grows and shrinks gently, like "Tap to Start" (D-017).
func test_play_breathes() -> void:
	await wait_seconds(0.4)  # Part way through the first breath.
	assert_gt(screen._play_breath.scale.x, 1.005)  # Play has grown a little.


# The title is DIVIRUSH with every letter on its own (so they can wave), and the tagline is back.
func test_title_letters_and_tagline() -> void:
	var word := ""  # The letters joined up.
	for label: Label in screen._title.find_children("*", "Label", true, false):  # Each letter, left to right ...
		word += label.text  # ... adds its letter.
	assert_eq(word, "DIVIRUSH")  # The game's name.
	assert_eq(screen._tagline.text, "Quick-tap division!")  # The tagline from the Start-up menu.


# The white pill shows the learner's total Stars out of 180 (D-017).
func test_star_pill_shows_the_total() -> void:
	var texts: Array[String] = []  # Every text on the pill.
	for label: Label in screen._star_pill.find_children("*", "Label", true, false):  # Each label on the pill ...
		texts.append(label.text)  # ... adds its text.
	assert_has(texts, "5/180")  # 3 + 2 Stars earned of 180.
