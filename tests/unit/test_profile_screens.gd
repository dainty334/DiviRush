# Tests for the Welcome screen, the Profile screen and the first-time path from the Start-up menu (D-030).
extends GutTest  # GUT gives this script its assert_* checks.

const SCREEN := "res://scenes/screens/%s.tscn"  # Screen scene paths.
const TEST_PATH := "user://test_profile_screens.cfg"  # A separate file, so tests never touch the real save.

var _real_progress: Progress  # The game's own progress, put back after each test.
var _real_records: Records  # The game's own records, put back after each test.
var _real_profile: Profile  # The game's own Profile, put back after each test.
var _real_store: SaveStore  # The game's own save file, put back after each test.


# Runs before every test: a first-time player in memory, saving to a test file only.
func before_each() -> void:
	_real_progress = Save.progress  # Keep the game's progress safe.
	_real_records = Save.records  # Keep the game's records safe.
	_real_profile = Save.profile  # Keep the game's Profile safe.
	_real_store = Save._store  # Keep the real save file safe.
	Save.progress = Progress.new()  # Fresh progress.
	Save.records = Records.new()  # Fresh records.
	Save.profile = Profile.new()  # No Nickname yet.
	Save._store = SaveStore.new(TEST_PATH)  # Saves go to the test file.


# Runs after every test: puts the game's own data back and deletes the test file.
func after_each() -> void:
	Save.progress = _real_progress  # Back to the real progress.
	Save.records = _real_records  # Back to the real records.
	Save.profile = _real_profile  # Back to the real Profile.
	Save._store = _real_store  # Back to the real save file.
	if FileAccess.file_exists(TEST_PATH):  # Only if a test saved.
		DirAccess.remove_absolute(TEST_PATH)  # Delete it.


# Opens a screen and returns it.
func _open(screen_name: String) -> Node:
	var screen: Node = load(SCREEN % screen_name).instantiate()  # A new screen.
	add_child_autofree(screen)  # In the tree (this builds it), freed after the test.
	return screen  # Hand it back.


# Returns every text inside a node, in tree order.
func _texts(node: Node) -> Array[String]:
	var texts: Array[String] = []  # The list to fill.
	for label in node.find_children("*", "Label", true, false):  # Each label ...
		texts.append((label as Label).text)  # ... adds its text.
	return texts  # Hand back the list.


# Types into a Nickname box the way a keyboard does, so its checks run.
func _type(box: NicknameBox, text: String) -> void:
	box.text = text  # The new text ...
	box.text_changed.emit(text)  # ... and the signal a keyboard sends.


# A first-time player goes from the Start-up menu to the Welcome screen; a player with a Nickname goes to the Main menu.
func test_start_goes_to_welcome_only_the_first_time() -> void:
	var start := _open("start_screen")  # The Start-up menu.
	assert_eq(start.next_screen(), "welcome_screen")  # No Nickname yet: Welcome.
	Save.profile.nickname = "Bea"  # Now she has one ...
	assert_eq(start.next_screen(), "main_menu")  # ... so the Main menu.


# The Welcome screen asks for a Nickname with the privacy tip, and for a Buddy, starting at Both.
func test_welcome_asks_nickname_and_buddy() -> void:
	var screen := _open("welcome_screen")  # The Welcome screen.
	var texts := _texts(screen)  # Every text on it.
	assert_has(texts, "What's your nickname?")  # The Nickname question.
	assert_has(texts, "Use a nickname, not your full name.")  # The privacy tip.
	assert_has(texts, "Who's your buddy?")  # The Buddy question.
	assert_eq(screen._picker.selected, "Both")  # Both, until the learner picks.


# Next stays off until a Nickname is typed, and signs that are not allowed are dropped as they are typed.
func test_next_waits_for_a_nickname() -> void:
	var screen := _open("welcome_screen")  # The Welcome screen.
	assert_true(screen._next.disabled)  # Nothing typed: Next is off.
	_type(screen._nickname, "   ")  # Only spaces ...
	assert_true(screen._next.disabled)  # ... still off.
	_type(screen._nickname, "Bea!")  # A Nickname with a sign ...
	assert_eq(screen._nickname.text, "Bea")  # ... loses the sign,
	assert_false(screen._next.disabled)  # ... and Next is on.


# Next keeps the Nickname and the Buddy and writes them to the save file.
func test_welcome_saves_the_choices() -> void:
	var screen := _open("welcome_screen")  # The Welcome screen.
	_type(screen._nickname, " Bea ")  # A Nickname with spaces at the ends.
	screen._picker.select("Migo", true)  # Migo picked.
	screen.save_choices()  # As Next does before opening the Main menu.
	assert_eq(Save.profile.nickname, "Bea")  # Kept without the spaces.
	assert_eq(Save.profile.buddy, "Migo")  # Migo kept.
	var loaded := Profile.new()  # As after a restart ...
	SaveStore.new(TEST_PATH).load_into(Progress.new(), SaveStore.default_settings(), null, loaded)  # ... read the file.
	assert_eq(loaded.nickname, "Bea")  # The Nickname was saved.
	assert_eq(loaded.buddy, "Migo")  # The Buddy was saved.


# The Profile shows the face, the Nickname, the Buddy and the three counts.
func test_profile_shows_the_learner() -> void:
	Save.profile.nickname = "Bea"  # Her Nickname.
	Save.profile.buddy = "Ana"  # Her Buddy.
	Save.progress.record(1, Difficulty.Kind.EASY, 1, 3, 250, 50.0)  # 3 Stars, 1 Level passed.
	Trophies.award(Save.progress, Save.records)  # "First Star" and "Perfect 10".
	var screen := _open("profile_screen")  # The Profile.
	var texts := _texts(screen)  # Every text on it.
	assert_has(texts, "Bea")  # The Nickname.
	assert_has(texts, "Your buddy")  # The Buddy heading.
	assert_eq(screen._picker.selected, "Ana")  # Ana is picked.
	assert_eq(screen._face().buddy, "Ana")  # Ana's face shows.
	for expected: String in ["3/180", "2/26", "1/60"]:  # Stars, Trophies and Levels passed ...
		assert_has(texts, expected, expected)  # ... each shows.


# Picking another Buddy saves it and changes the face at once.
func test_profile_changes_the_buddy() -> void:
	Save.profile.nickname = "Bea"  # A Nickname.
	var screen := _open("profile_screen")  # The Profile, with Both.
	screen._picker.select("Migo", true)  # Migo picked.
	assert_eq(Save.profile.buddy, "Migo")  # Saved.
	await wait_physics_frames(1)  # Let the old face go.
	assert_eq(screen._face().buddy, "Migo")  # Migo's face shows.


# The pencil opens a card to change the Nickname; Save keeps a good one, and stays off for a bad one.
func test_profile_changes_the_nickname() -> void:
	Save.profile.nickname = "Bea"  # A Nickname.
	var screen := _open("profile_screen")  # The Profile.
	screen._pencil.pressed.emit()  # The pencil is tapped.
	assert_true(screen._edit_card.visible)  # The card shows ...
	assert_eq(screen._edit_box.text, "Bea")  # ... with the Nickname in its box.
	_type(screen._edit_box, "")  # Everything deleted ...
	assert_true(screen._save_button.disabled)  # ... so Save is off.
	_type(screen._edit_box, "Bianca")  # A new Nickname ...
	screen._save_button.pressed.emit()  # ... saved.
	assert_eq(Save.profile.nickname, "Bianca")  # Kept.
	assert_has(_texts(screen), "Bianca")  # Shown.
	assert_false(screen._edit_card.visible)  # The card closes.


# Before any Trophy is earned, the Featured Trophy place says how to fill it (D-031).
func test_featured_trophy_before_any_trophy() -> void:
	Save.profile.nickname = "Bea"  # A Nickname, no Trophies.
	var screen := _open("profile_screen")  # The Profile.
	assert_has(_texts(screen), "Featured Trophy")  # The heading.
	assert_has(_texts(screen), "Earn a Trophy to show it here.")  # What to do.
	assert_true(screen._featured_button.disabled)  # Nothing to pick yet.


# Picking a Featured Trophy saves it and shows it big on the Profile; None takes it away (D-031).
func test_pick_a_featured_trophy() -> void:
	Save.profile.nickname = "Bea"  # A Nickname.
	Save.records.trophies.assign(["first_star", "perfect_10"])  # Two Trophies earned.
	var screen := _open("profile_screen")  # The Profile.
	assert_has(_texts(screen), "Tap to pick a Trophy")  # None picked yet.
	screen._featured_button.pressed.emit()  # Tap the Featured Trophy place.
	assert_true(screen._featured_card.visible)  # The picker shows ...
	assert_eq(screen._featured_choices.size(), 2)  # ... with the two earned Trophies.
	screen._featured_choices[1].pressed.emit()  # Pick "Perfect 10".
	assert_eq(Save.profile.featured, "perfect_10")  # Saved.
	assert_false(screen._featured_card.visible)  # The picker closes.
	assert_has(_texts(screen), "Perfect 10")  # Its name shows on the Profile.
	screen._featured_button.pressed.emit()  # Open the picker again ...
	screen._featured_none.pressed.emit()  # ... and pick None.
	assert_eq(Save.profile.featured, "")  # Nothing featured.


# Back while the Nickname card is open closes the card instead of leaving the Profile.
func test_back_closes_the_nickname_card() -> void:
	Save.profile.nickname = "Bea"  # A Nickname.
	var screen := _open("profile_screen")  # The Profile.
	screen._pencil.pressed.emit()  # The card opens.
	screen.back_pressed()  # Android Back.
	assert_false(screen._edit_card.visible)  # The card closes.
