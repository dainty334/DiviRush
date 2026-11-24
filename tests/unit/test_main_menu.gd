# Tests for the Main menu (D-022, D-025, D-030): no title, the Profile pill at the top left, the
# chosen Buddy, a big breathing Play button, and How to Play, Trophies, Settings and Exit in the bottom bar.
extends GutTest  # GUT gives this script its assert_* checks.

const MAIN_MENU := "res://scenes/screens/main_menu.tscn"  # The Main menu scene.

var screen: Node  # A fresh Main menu for each test.
var _real_progress: Progress  # The game's own progress, put back after each test.
var _real_records: Records  # The game's own records, put back after each test.
var _real_profile: Profile  # The game's own Profile, put back after each test.


# Runs before every test: gives the learner the Nickname "Bea" and 3 + 2 Stars (2 Levels passed,
# "First Star" earned) in memory only, then opens a new Main menu.
func before_each() -> void:
	_real_progress = Save.progress  # Keep the game's progress safe.
	_real_records = Save.records  # Keep the game's records safe.
	_real_profile = Save.profile  # Keep the game's Profile safe.
	Save.progress = Progress.new()  # Fresh progress in memory only.
	Save.records = Records.new()  # Fresh records in memory only.
	Save.profile = Profile.new()  # A Profile in memory only ...
	Save.profile.nickname = "Bea"  # ... with a Nickname.
	Save.progress.record(1, Difficulty.Kind.EASY, 1, 3, 250, 50.0)  # Episode 1 Easy Level 1: 3 Stars.
	Save.progress.record(2, Difficulty.Kind.EASY, 1, 2, 200, 60.0)  # Episode 2 Easy Level 1: 2 Stars.
	Trophies.award(Save.progress, Save.records)  # "First Star" and "Perfect 10" earned.
	screen = load(MAIN_MENU).instantiate()  # A new Main menu.
	add_child_autofree(screen)  # In the tree (this builds it), freed after the test.


# Runs after every test: puts the game's own progress and records back.
func after_each() -> void:
	Save.progress = _real_progress  # Back to the real progress.
	Save.records = _real_records  # Back to the real records.
	Save.profile = _real_profile  # Back to the real Profile.


# Returns every text shown inside a node (the whole screen when none is given), in tree order.
func _texts(node: Node = null) -> Array[String]:
	var texts: Array[String] = []  # The list to fill.
	for label in (node if node != null else screen).find_children("*", "Label", true, false):  # Each label ...
		texts.append((label as Label).text)  # ... adds its text.
	return texts  # Hand back the list.


# The buttons: Play, then How to Play, Trophies, Settings and Exit in the bottom bar (D-030).
func test_buttons_in_order() -> void:
	var words: Array[String] = []  # The buttons' words.
	for button: Button in screen._buttons:  # Each button ...
		words.append(button.text)  # ... adds its words.
	assert_eq(words, ["Play", "How to Play", "Trophies", "Settings", "Exit"] as Array[String])  # Play, then the bottom bar.


# Each button shows its own drawn icon.
func test_every_button_has_its_icon() -> void:
	var icons := SpriteSheet.icons()  # Every icon frame.
	var expected := [UiKit.Icon.PLAY, UiKit.Icon.HELP, UiKit.Icon.TROPHY, UiKit.Icon.GEAR, UiKit.Icon.EXIT]  # In order.
	for i in range(expected.size()):  # Each button ...
		var pictures: Array[Node] = screen._buttons[i].find_children("*", "TextureRect", true, false)  # ... its pictures,
		assert_eq(pictures.size(), 1, screen._buttons[i].text)  # ... exactly one icon,
		assert_eq((pictures[0] as TextureRect).texture, icons[expected[i]], screen._buttons[i].text)  # ... the right one.


# The Main menu has no title and no tagline any more; the Start-up menu keeps them (D-022).
func test_no_title() -> void:
	var all_text := "".join(_texts())  # Every text, joined up.
	assert_false(all_text.contains("DIVIRUSH"), "no DIVIRUSH title")  # No title, not even letter by letter.
	assert_false(all_text.contains("Quick-tap"), "no tagline")  # No tagline.


# The count pills left the Main menu for the Profile (D-030), so no counts show here.
func test_no_count_pills() -> void:
	var texts := _texts()  # Every text on the screen.
	assert_does_not_have(texts, "5/180")  # No Stars count.
	assert_does_not_have(texts, "2/12")  # No Trophies count.
	assert_does_not_have(texts, "2/60")  # No Levels passed count.


# The Profile pill at the top left shows the Buddy's face and the Nickname (D-030).
func test_profile_pill() -> void:
	var pill: Button = screen._profile_button  # The pill.
	assert_has(_texts(pill), "Bea")  # The Nickname.
	var faces := pill.find_children("*", "BuddyFace", true, false)  # The faces on it ...
	assert_eq(faces.size(), 1)  # ... in one BuddyFace,
	assert_eq((faces[0] as BuddyFace).buddy, "Both")  # ... showing Both.
	assert_true(pill.size.x >= pill.get_child(0).get_combined_minimum_size().x)  # Wide enough for its face and Nickname.


# A learner who picked one Buddy sees only that mascot, every visit (D-030).
func test_only_the_chosen_buddy_shows() -> void:
	Save.profile.buddy = "Migo"  # Only Migo.
	for visit in range(2):  # Two more visits, which would have taken turns before ...
		var menu: Node = load(MAIN_MENU).instantiate()  # ... a new Main menu,
		add_child_autofree(menu)  # ... built,
		assert_eq(menu._mascot.mascot_name, "Migo")  # ... shows Migo each time.


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
