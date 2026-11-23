# Tests for the Exit confirmation (D-021): Exit on the Main menu, and Android Back on the Start-up
# menu, show a "Leave DiviRush?" card with Stay and Exit, instead of closing the game at once.
extends GutTest  # GUT gives this script its assert_* checks.

const SCREEN := "res://scenes/screens/%s.tscn"  # Screen scene paths.


# Opens a screen and returns it.
func _open(screen_name: String) -> Node:
	var screen: Node = load(SCREEN % screen_name).instantiate()  # A new screen.
	add_child_autofree(screen)  # In the tree (this builds it), freed after the test.
	return screen  # Hand it back.


# Returns the words on the buttons of the Exit card, top to bottom.
func _card_buttons(screen: Node) -> Array[String]:
	var words: Array[String] = []  # The list to fill.
	for node in screen._exit_card.find_children("*", "Button", true, false):  # Each button on the card ...
		words.append((node as Button).text)  # ... adds its words.
	return words  # Hand back the list.


# Tapping Exit on the Main menu shows the card with Stay and Exit; it does not close the game.
func test_exit_button_shows_the_card() -> void:
	var menu := _open("main_menu")  # The Main menu.
	assert_false(menu.is_exit_card_open())  # No card at first.
	menu._buttons[menu._buttons.size() - 1].pressed.emit()  # Tap Exit (the last button).
	assert_true(menu.is_exit_card_open())  # The card shows.
	assert_eq(_card_buttons(menu), ["Stay", "Exit"] as Array[String])  # Stay first and biggest, then Exit.


# Stay closes the card, and the learner is still on the Main menu.
func test_stay_closes_the_card() -> void:
	var menu := _open("main_menu")  # The Main menu.
	menu.show_exit_card()  # The card shows.
	var stay: Button = menu._exit_card.find_children("*", "Button", true, false)[0]  # The Stay button.
	stay.pressed.emit()  # Tap Stay.
	assert_false(menu.is_exit_card_open())  # The card is gone.


# The card's Exit button is the one that saves and closes the game.
func test_card_exit_closes_the_game() -> void:
	var menu := _open("main_menu")  # The Main menu.
	menu.show_exit_card()  # The card shows.
	var leave: Button = menu._exit_card.find_children("*", "Button", true, false)[1]  # The Exit button on the card.
	assert_true(leave.pressed.is_connected(Game.quit_game))  # It saves and closes the game.


# Android Back while the card is open is the same as Stay: the card closes and the screen stays.
func test_back_while_card_open_is_stay() -> void:
	var menu := _open("main_menu")  # The Main menu.
	menu.show_exit_card()  # The card shows.
	menu.back_pressed()  # Android Back (or Escape on a PC).
	assert_false(menu.is_exit_card_open())  # The card is gone.


# Android Back on the Start-up menu shows the same card instead of closing the game, and a tap
# while the card is open does not jump on to the Main menu.
func test_start_screen_back_shows_the_card() -> void:
	var start := _open("start_screen")  # The Start-up menu.
	start.back_pressed()  # Android Back.
	assert_true(start.is_exit_card_open())  # The card shows.
	var tap := InputEventMouseButton.new()  # A tap ...
	tap.button_index = MOUSE_BUTTON_LEFT  # ... with the left button (a finger on a phone),
	tap.pressed = true  # ... going down.
	start._input(tap)  # The screen sees the tap.
	assert_false(start._leaving)  # It does not leave for the Main menu while the card is open.
