# Tests for the Trophies screen with its Trophies and Records tabs, the Trophy card, and the
# Trophy banner on Level end (D-023, D-030).
extends GutTest  # GUT gives this script its assert_* checks.

const SCREEN := "res://scenes/screens/%s.tscn"  # Screen scene paths.

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


# The Trophies screen shows all twelve, in order, and how many are earned.
func test_trophies_screen_shows_all_twelve() -> void:
	Save.records.trophies.assign(["first_star"])  # One Trophy earned.
	var screen := _open("trophies_screen")  # The Trophies screen.
	assert_eq(screen._cards.size(), 26)  # 26 cards (D-031).
	assert_has(_texts(screen), "1 of 26 earned")  # How many are earned.
	for i in range(26):  # Each card ...
		assert_has(_texts(screen._cards[i]), Trophies.ALL[i].name)  # ... shows its Trophy's name, in order.


# An earned Trophy shows in colour with no lock; one not yet earned shows a lock and its goal.
func test_locked_trophies_show_their_goal() -> void:
	Save.records.trophies.assign(["first_star"])  # Only "First Star" earned.
	var screen := _open("trophies_screen")  # The Trophies screen.
	var lock: Texture2D = SpriteSheet.icons()[UiKit.Icon.LOCK]  # The lock picture.
	var first_pictures: Array = screen._cards[0].find_children("*", "TextureRect", true, false).map(func(n: Node) -> Texture2D: return (n as TextureRect).texture)  # "First Star" card's pictures.
	var second_pictures: Array = screen._cards[1].find_children("*", "TextureRect", true, false).map(func(n: Node) -> Texture2D: return (n as TextureRect).texture)  # "Perfect 10" card's pictures.
	assert_does_not_have(first_pictures, lock)  # Earned: no lock.
	assert_has(second_pictures, lock)  # Not earned: a lock ...
	assert_has(_texts(screen._cards[1]), Trophies.ALL[1].goal)  # ... and its goal.


# The Records tab shows the game records as plain numbers, not grades (D-030).
func test_records_tab_shows_the_records() -> void:
	Save.progress.record(1, Difficulty.Kind.EASY, 1, 3, 250, 50.0)  # 3 Stars in Episode 1.
	Save.progress.record(2, Difficulty.Kind.EASY, 1, 1, 120, 70.0)  # 1 Star in Episode 2.
	Save.records.levels_played = 7  # 7 Levels played.
	Save.records.correct_total = 63  # 63 correct answers.
	Save.records.best_streak = 8  # 8 in a row.
	Save.records.seconds_played = 750.0  # 12 minutes 30 seconds.
	var screen := _open("trophies_screen")  # The Trophies screen.
	screen.show_tab(1)  # The Records tab.
	assert_true(screen._pages[1].visible)  # Records show ...
	assert_false(screen._pages[0].visible)  # ... instead of the Trophies.
	var texts := _texts(screen._pages[1])  # Every text on the Records tab.
	for expected: String in ["4 of 180", "2 of 60", "7", "63", "8 in a row", "12 min"]:  # Stars, Levels passed, played, correct, streak, time ...
		assert_has(texts, expected, expected)  # ... each shows.
	for expected: String in ["3/45", "1/45", "0/45"]:  # Stars in Episodes 1, 2 and 3 (and 4) ...
		assert_has(texts, expected, expected)  # ... show next to their bars.


# Each Trophy card shows its own picture (D-031): in colour when earned, grey with a small lock when not.
func test_each_trophy_has_its_own_picture() -> void:
	Save.records.trophies.assign(["first_star"])  # Only "First Star" earned.
	var screen := _open("trophies_screen")  # The Trophies screen.
	var pictures := SpriteSheet.trophies()  # Every Trophy picture.
	for i in range(26):  # Each card ...
		var shown: Array = screen._cards[i].find_children("*", "TextureRect", true, false).map(func(n: Node) -> Texture2D: return (n as TextureRect).texture)  # ... its pictures,
		assert_has(shown, pictures[i], Trophies.ALL[i].id)  # ... include its own.
	var earned_picture := _picture_of(screen._cards[0], pictures[0])  # "First Star", earned.
	var locked_picture := _picture_of(screen._cards[1], pictures[1])  # "Perfect 10", not earned.
	assert_null(earned_picture.material)  # Earned: in colour.
	assert_not_null(locked_picture.material)  # Not earned: grey.


# Returns the picture node showing a texture inside a card.
func _picture_of(card: Node, texture: Texture2D) -> TextureRect:
	for node in card.find_children("*", "TextureRect", true, false):  # Each picture on the card ...
		if (node as TextureRect).texture == texture:  # ... the one with this texture ...
			return node  # ... is handed back.
	return null  # Not found.


# The Trophies screen opens on the Trophies tab, and its two tabs are called Trophies and Records.
func test_two_tabs() -> void:
	var screen := _open("trophies_screen")  # The Trophies screen.
	var names: Array[String] = []  # The tab words.
	for tab: Button in screen._tabs:  # Each tab ...
		names.append(tab.text)  # ... adds its word.
	assert_eq(names, ["Trophies", "Records"] as Array[String])  # Trophies, then Records.
	assert_true(screen._pages[0].visible)  # The Trophies show first.
	assert_false(screen._pages[1].visible)  # The Records wait.


# Tapping an earned Trophy opens its card with its name, goal and the day it was earned.
func test_tap_an_earned_trophy() -> void:
	Save.records.trophies.assign(["first_star"])  # "First Star" earned ...
	Save.records.trophy_dates["first_star"] = "2026-11-24"  # ... on 24 November 2026.
	var screen := _open("trophies_screen")  # The Trophies screen.
	screen._cards[0].pressed.emit()  # Tap "First Star".
	assert_true(screen.is_trophy_card_open())  # Its card shows ...
	var texts := _texts(screen._trophy_card)  # ... with:
	assert_has(texts, "First Star")  # ... its name,
	assert_has(texts, "Earn your first Star")  # ... its goal,
	assert_has(texts, "Earned on 24 Nov 2026")  # ... and its day.


# A Trophy earned before days were kept says so, truthfully.
func test_tap_an_older_trophy() -> void:
	Save.records.trophies.assign(["first_star"])  # Earned, with no day kept.
	var screen := _open("trophies_screen")  # The Trophies screen.
	screen._cards[0].pressed.emit()  # Tap "First Star".
	assert_has(_texts(screen._trophy_card), "Earned before dates were kept")  # No made-up day.


# Tapping a Trophy not yet earned shows its goal and how far along the learner is.
func test_tap_a_locked_trophy() -> void:
	Save.progress.record(1, Difficulty.Kind.EASY, 1, 2, 200, 60.0)  # 2 Stars so far.
	var screen := _open("trophies_screen")  # The Trophies screen.
	screen._cards[9].pressed.emit()  # Tap "Star Collector".
	var texts := _texts(screen._trophy_card)  # Its card's words:
	assert_has(texts, "Star Collector")  # ... its name,
	assert_has(texts, "Earn 50 Stars")  # ... its goal,
	assert_has(texts, "2 of 50 Stars")  # ... and how far along.


# OK, and Android Back, close the Trophy card without leaving the screen.
func test_close_the_trophy_card() -> void:
	var screen := _open("trophies_screen")  # The Trophies screen.
	screen._cards[0].pressed.emit()  # Open a card.
	screen.back_pressed()  # Android Back ...
	assert_false(screen.is_trophy_card_open())  # ... closes it.
	screen._cards[1].pressed.emit()  # Open another.
	screen._trophy_ok.pressed.emit()  # OK ...
	assert_false(screen.is_trophy_card_open())  # ... closes it too.


# A play that earns Trophies shows the banner with their names on Level end; a play that earns none does not.
func test_level_end_trophy_banner() -> void:
	Game.episode = 1  # Episode 1.
	Game.difficulty = Difficulty.Kind.EASY  # Easy.
	Game.level = 1  # Level 1.
	Game.last_result = {"correct": 10, "total": 10, "stars": 3, "score": 250, "time": 40.0, "passed": true, "new_best": true, "new_trophies": ["first_star", "perfect_10"]}  # Two Trophies earned.
	var screen := _open("level_end")  # Level end.
	assert_not_null(screen._trophy_banner)  # The banner is there ...
	var texts := _texts(screen._trophy_banner)  # ... with its words:
	assert_has(texts, "Trophy earned!")  # ... the heading,
	assert_has(texts, "First Star")  # ... and each Trophy's name.
	assert_has(texts, "Perfect 10")  # Both of them.
	Game.last_result = {"correct": 8, "total": 10, "stars": 1, "score": 120, "time": 60.0, "passed": true, "new_best": false, "new_trophies": []}  # No Trophy this time.
	assert_null(_open("level_end")._trophy_banner)  # No banner.
