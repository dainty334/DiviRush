# Tests for How to Play as picture lessons taught by the Buddy (D-032): seven pages turned with
# arrows, a line from the Buddy on each, and a "Try it!" item at the end that is never saved.
extends GutTest  # GUT gives this script its assert_* checks.

const SCREEN := "res://scenes/screens/how_to_play.tscn"  # The How to Play scene.

var _real_profile: Profile  # The game's own Profile, put back after each test.
var _real_records: Records  # The game's own records, put back after each test.


# Runs before every test: a learner with the Buddy "Both" and no plays, in memory only.
func before_each() -> void:
	_real_profile = Save.profile  # Keep the game's Profile safe.
	_real_records = Save.records  # Keep the game's records safe.
	Save.profile = Profile.new()  # Both, in memory only.
	Save.profile.nickname = "Bea"  # A Nickname.
	Save.records = Records.new()  # No plays.


# Runs after every test: puts the game's own data back.
func after_each() -> void:
	Save.profile = _real_profile  # Back to the real Profile.
	Save.records = _real_records  # Back to the real records.


# Opens How to Play and returns it.
func _open() -> Node:
	var screen: Node = load(SCREEN).instantiate()  # A new screen.
	add_child_autofree(screen)  # In the tree (this builds it), freed after the test.
	return screen  # Hand it back.


# Returns every text inside a node, in tree order.
func _texts(node: Node) -> Array[String]:
	var texts: Array[String] = []  # The list to fill.
	for label in node.find_children("*", "Label", true, false):  # Each label ...
		texts.append((label as Label).text)  # ... adds its text.
	return texts  # Hand back the list.


# There are seven lessons; the first page shows "1 / 7", its title, its picture and the Buddy's line.
func test_seven_pages_start_at_one() -> void:
	var screen := _open()  # How to Play.
	assert_eq(screen.LESSONS.size(), 7)  # Seven lessons.
	assert_eq(screen._pager.count, 7)  # Seven pages.
	assert_eq(screen._pager.label_text(), "1 / 7")  # On page 1.
	assert_eq(screen._words.text, screen.LESSONS[0].line)  # The Buddy says the first line.
	assert_has(_texts(screen), screen.LESSONS[0].title)  # The first title shows.
	assert_true(screen._pager._prev.disabled)  # No page before the first.


# The right arrow turns to the next page with its own line; the left arrow goes back.
func test_arrows_turn_the_pages() -> void:
	var screen := _open()  # How to Play.
	screen._pager.next()  # The right arrow.
	assert_eq(screen._pager.label_text(), "2 / 7")  # Page 2.
	assert_eq(screen._words.text, screen.LESSONS[1].line)  # Its line.
	screen._pager.previous()  # The left arrow.
	assert_eq(screen._pager.label_text(), "1 / 7")  # Back to page 1.
	screen._pager.swipe(-300.0)  # A swipe to the left ...
	assert_eq(screen._pager.label_text(), "2 / 7")  # ... also turns the page.


# With the Buddy "Both", Ana and Migo take turns page by page; with one Buddy, only that one teaches.
func test_the_buddy_teaches() -> void:
	var screen := _open()  # How to Play, Both.
	assert_eq(screen._teacher.mascot_name, "Ana")  # Ana on page 1 ...
	screen._pager.next()  # ... then
	assert_eq(screen._teacher.mascot_name, "Migo")  # ... Migo on page 2.
	Save.profile.buddy = "Migo"  # Only Migo now.
	var only_migo := _open()  # How to Play again.
	only_migo._pager.next()  # Page 2 ...
	assert_eq(only_migo._teacher.mascot_name, "Migo")  # ... Migo.
	only_migo._pager.next()  # Page 3 ...
	assert_eq(only_migo._teacher.mascot_name, "Migo")  # ... still Migo.


# The lessons are in Grade 4 words with no points rules, and the Easy, Medium and Hard page gives the real numbers.
func test_lesson_words() -> void:
	var screen := _open()  # How to Play.
	for lesson: Dictionary in screen.LESSONS:  # Each lesson ...
		assert_false(lesson.line.to_lower().contains("point"), lesson.title)  # ... leaves out points (D-032).
	screen._pager.show_page(5)  # The Easy, Medium and Hard page.
	var texts := _texts(screen._stage)  # Its picture's words.
	for expected: String in ["Easy", "Medium", "Hard", "15 s", "10 s", "7 s"]:  # Names and timers (D-008) ...
		assert_has(texts, expected, expected)  # ... each shows.


# "Got it!" shows only on the last page.
func test_got_it_on_the_last_page() -> void:
	var screen := _open()  # How to Play.
	assert_false(screen._got_it.visible)  # Not on page 1.
	screen._pager.show_page(6)  # The last page.
	assert_true(screen._got_it.visible)  # Now it shows.
	assert_true(screen._pager._next.disabled)  # No page after the last.


# Try it: a wrong tap shakes and the Buddy gives the times-table hint; the right tap cheers. Nothing is saved.
func test_try_it() -> void:
	var screen := _open()  # How to Play.
	screen._pager.show_page(6)  # The "Try it!" page.
	assert_eq(screen._try_bubbles.size(), 3)  # Three Easy bubbles.
	var wrong: AnswerBubble = null  # A wrong bubble ...
	var right: AnswerBubble = null  # ... and the right one.
	for bubble: AnswerBubble in screen._try_bubbles:  # Look at each ...
		if bubble.value == 4:  # ... 12 ÷ 3 = 4 ...
			right = bubble  # ... is right,
		else:  # ... any other ...
			wrong = bubble  # ... is wrong.
	screen._on_try_tapped(wrong)  # A wrong tap.
	assert_false(screen._try_done)  # Not done yet.
	assert_true(screen._words.text.contains("3 times what is 12"))  # The times-table hint.
	screen._on_try_tapped(right)  # The right tap.
	assert_true(screen._try_done)  # Done.
	assert_true(screen._words.text.contains("12 ÷ 3 = 4"))  # The cheer says the answer.
	assert_eq(Save.records.levels_played, 0)  # Nothing was saved as a play.


# After the Welcome screen, Next opens the lessons once (D-032).
func test_welcome_goes_to_the_lessons() -> void:
	var welcome: Node = load("res://scenes/screens/welcome_screen.tscn").instantiate()  # The Welcome screen.
	add_child_autofree(welcome)  # Built.
	assert_eq(welcome.next_screen(), "how_to_play")  # Next opens How to Play.
