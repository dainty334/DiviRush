# Tests for the Main menu home dashboard (D-022): no title, a "My progress" card, a big breathing
# Play button, four icon tiles, and a small Exit, all straight and lined up.
extends GutTest  # GUT gives this script its assert_* checks.

const MAIN_MENU := "res://scenes/screens/main_menu.tscn"  # The Main menu scene.

var screen: Node  # A fresh Main menu for each test.
var _real_progress: Progress  # The game's own progress, put back after each test.
var _real_records: Records  # The game's own records, put back after each test.


# Runs before every test: gives the learner 3 + 2 Stars (2 Levels passed, "First Star" earned)
# in memory only, then opens a new Main menu.
func before_each() -> void:
	_real_progress = Save.progress  # Keep the game's progress safe.
	_real_records = Save.records  # Keep the game's records safe.
	Save.progress = Progress.new()  # Fresh progress in memory only.
	Save.records = Records.new()  # Fresh records in memory only.
	Save.progress.record(1, Difficulty.Kind.EASY, 1, 3, 250, 50.0)  # Episode 1 Easy Level 1: 3 Stars.
	Save.progress.record(2, Difficulty.Kind.EASY, 1, 2, 200, 60.0)  # Episode 2 Easy Level 1: 2 Stars.
	Trophies.award(Save.progress, Save.records)  # "First Star" and "Perfect 10" earned.
	screen = load(MAIN_MENU).instantiate()  # A new Main menu.
	add_child_autofree(screen)  # In the tree (this builds it), freed after the test.


# Runs after every test: puts the game's own progress and records back.
func after_each() -> void:
	Save.progress = _real_progress  # Back to the real progress.
	Save.records = _real_records  # Back to the real records.


# Returns every text shown on the screen, in tree order.
func _texts() -> Array[String]:
	var texts: Array[String] = []  # The list to fill.
	for label in screen.find_children("*", "Label", true, false):  # Each label ...
		texts.append((label as Label).text)  # ... adds its text.
	return texts  # Hand back the list.


# The buttons: Play, the four in the bottom bar, and Exit, which sits at the top right (D-025).
func test_buttons_in_order() -> void:
	var words: Array[String] = []  # The buttons' words.
	for button: Button in screen._buttons:  # Each button ...
		words.append(button.text)  # ... adds its words.
	assert_eq(words, ["Play", "How to Play", "Trophies", "My Records", "Settings", "Exit"] as Array[String])  # Play, the bottom bar, then Exit (top right).


# Each button shows its own drawn icon.
func test_every_button_has_its_icon() -> void:
	var icons := SpriteSheet.icons()  # Every icon frame.
	var expected := [UiKit.Icon.PLAY, UiKit.Icon.HELP, UiKit.Icon.TROPHY, UiKit.Icon.CHART, UiKit.Icon.GEAR, UiKit.Icon.EXIT]  # In order.
	for i in range(expected.size()):  # Each button ...
		var pictures: Array[Node] = screen._buttons[i].find_children("*", "TextureRect", true, false)  # ... its pictures,
		assert_eq(pictures.size(), 1, screen._buttons[i].text)  # ... exactly one icon,
		assert_eq((pictures[0] as TextureRect).texture, icons[expected[i]], screen._buttons[i].text)  # ... the right one.


# The Main menu has no title and no tagline any more; the Start-up menu keeps them (D-022).
func test_no_title() -> void:
	var all_text := "".join(_texts())  # Every text, joined up.
	assert_false(all_text.contains("DIVIRUSH"), "no DIVIRUSH title")  # No title, not even letter by letter.
	assert_false(all_text.contains("Quick-tap"), "no tagline")  # No tagline.


# The "My progress" card shows Stars of 180, Trophies of 12 and Levels passed of 60.
func test_progress_card() -> void:
	var texts := _texts()  # Every text on the screen.
	assert_has(texts, "5/180")  # 3 + 2 Stars.
	assert_has(texts, "2/12")  # "First Star" and "Perfect 10".
	assert_has(texts, "2/60")  # Two Levels passed.


# Once they have popped in, the buttons stand straight, and the four bottom-bar buttons share one size, so they line up.
func test_buttons_stand_straight_and_tiles_line_up() -> void:
	await wait_seconds(1.3)  # Let the pop-in finish.
	for button: Button in screen._buttons:  # Each button ...
		assert_almost_eq(button.rotation, 0.0, 0.0001, button.text)  # ... stands straight.
	for i in range(1, 5):  # The four bottom-bar buttons ...
		assert_eq(screen._buttons[i].size, screen._buttons[1].size, screen._buttons[i].text)  # ... are the same size.


# Only Play moves on its own: it grows and shrinks gently (D-017, kept by D-022).
func test_play_breathes() -> void:
	await wait_seconds(0.4)  # Part way through the first breath.
	assert_gt(screen._play_breath.scale.x, 1.005)  # Play has grown a little.
