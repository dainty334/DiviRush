# Tests for pausing a Level when the app leaves the screen (D-015): the timer keeps its time,
# a "Paused" card covers the item, and "Go on" brings the item back.
extends GutTest  # GUT gives this script its assert_* checks.

const PLAY_SCREEN := "res://scenes/screens/play_screen.tscn"  # The Play screen scene.

var screen: Node  # A fresh Play screen for each test.


# Runs before every test: opens Episode 1, Easy, Level 1 on a new Play screen.
func before_each() -> void:
	Game.episode = 1  # Episode 1.
	Game.difficulty = Difficulty.Kind.EASY  # Easy.
	Game.level = 1  # Level 1.
	screen = load(PLAY_SCREEN).instantiate()  # A new Play screen.
	add_child_autofree(screen)  # In the tree (this builds it), freed after the test.


# Leaving the app stops the timer: time passing while paused does not count.
func test_pause_keeps_the_time_left() -> void:
	screen._time_left = 9.0  # 9 seconds left on the item.
	screen.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)  # The app leaves the screen.
	screen._process(5.0)  # 5 seconds pass while away.
	assert_almost_eq(screen._time_left, 9.0, 0.001)  # Still 9 seconds.
	assert_true(screen.is_paused())  # The Level is paused.


# While paused, the "Paused" card shows and the item and bubbles are hidden, so there is no free thinking time.
func test_pause_card_covers_the_item() -> void:
	screen.pause_level()  # Pause.
	assert_true(screen._pause_card.visible)  # The card shows.
	assert_false(screen._card.visible)  # The item card is hidden.
	assert_false(screen._bubble_area.visible)  # The bubbles are hidden.


# "Go on" hides the card, shows the item again, and the timer runs on from where it stopped.
func test_go_on_resumes_with_the_time_left() -> void:
	screen._time_left = 6.0  # 6 seconds left.
	screen.pause_level()  # Pause.
	screen.resume_level()  # Tap "Go on".
	assert_false(screen.is_paused())  # Not paused now.
	assert_false(screen._pause_card.visible)  # The card is gone.
	assert_true(screen._card.visible)  # The item is back.
	assert_true(screen._bubble_area.visible)  # The bubbles are back.
	screen._process(1.0)  # 1 second passes.
	assert_almost_eq(screen._time_left, 5.0, 0.001)  # The timer runs on: 5 seconds left.


# The feedback wait between items also stops while the app is away (D-015 working value).
func test_pause_stops_the_feedback_wait() -> void:
	screen._wait.start(0.9)  # A feedback pause is running.
	screen.pause_level()  # The app leaves the screen.
	assert_true(screen._wait.paused)  # The wait is held.
	screen.resume_level()  # Back again.
	assert_false(screen._wait.paused)  # The wait goes on.


# Android's "app paused" signal pauses the Level too, and a second pause changes nothing.
func test_app_paused_signal_also_pauses() -> void:
	screen.notification(Node.NOTIFICATION_APPLICATION_PAUSED)  # Android sends the app to the background.
	screen.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)  # Focus is lost as well.
	assert_true(screen.is_paused())  # Paused once.
	screen.resume_level()  # One "Go on" is enough.
	assert_false(screen.is_paused())  # Playing again.


# A finished Level does not pause, so the Level end is never covered by the card.
func test_finished_level_does_not_pause() -> void:
	screen._state = screen.State.FINISHED  # The Level has ended.
	screen.pause_level()  # The app leaves the screen.
	assert_false(screen.is_paused())  # Nothing to pause.
