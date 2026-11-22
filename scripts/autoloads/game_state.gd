# The "Game" autoload: remembers which Episode, Difficulty and Level the learner chose,
# loads the item banks, sets the game-wide look, and changes screens with a fade.
extends Node  # Autoloads are nodes that live for the whole game.

const SCREEN_PATH := "res://scenes/screens/%s.tscn"  # Where the screen scenes are.
const EPISODE_PATH := "res://resources/episodes/episode_%d.tres"  # Where the item banks are.
const FADE_SECONDS := 0.18  # Half of a screen change.

var episodes: Array[EpisodeData] = []  # All four Episodes, in order.
var episode := 1  # Chosen Episode, 1 to 4.
var difficulty: int = Difficulty.Kind.EASY  # Chosen Difficulty.
var level := 1  # Chosen Level, 1 to 5.
var last_result: Dictionary = {}  # Result of the last play, read by the Level end screen.
var _veil: ColorRect  # Full-screen colour used for the fade between screens.
var _changing := false  # true while a screen change runs, so double taps are ignored.


# Runs once when the game starts: loads the item banks, sets the theme and makes the fade layer.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keep working even if the game is paused.
	for number in range(1, Progress.EPISODE_COUNT + 1):  # Episodes 1 to 4 ...
		episodes.append(load(EPISODE_PATH % number))  # ... loaded from their item banks.
	get_tree().root.theme = UiKit.build_theme()  # Every screen uses the DiviRush theme.
	var layer := CanvasLayer.new()  # A layer drawn above every screen.
	layer.layer = 100  # Very high, so it covers everything.
	add_child(layer)  # Keep it for the whole game.
	_veil = ColorRect.new()  # The fade colour.
	_veil.color = Color(Palette.SKY_BOTTOM, 0.0)  # Sky blue, see-through at first.
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)  # Cover the screen.
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let taps through when not fading.
	layer.add_child(_veil)  # Show it on the layer.


# Returns the item bank of an Episode (the chosen one if no number is given).
func episode_data(number: int = 0) -> EpisodeData:
	return episodes[(number if number > 0 else episode) - 1]  # Lists start at 0, Episodes at 1.


# Returns the chosen Level's items.
func level_data() -> LevelData:
	return episode_data().levels[level - 1]  # Lists start at 0, Levels at 1.


# Returns true when a Difficulty of an Episode has the items it needs to be played.
# In this first slice only Episode 1 Easy has them; others show "Coming soon".
func is_playable(episode_number: int, kind: int) -> bool:
	var data := episode_data(episode_number)  # That Episode's item bank.
	if not data.is_built() or data.levels[0].items.is_empty():  # No Levels or no items yet ...
		return false  # ... so it cannot be played.
	var first: DivisionItem = data.levels[0].items[0]  # Look at one item.
	return first.wrong_for(kind).size() >= Difficulty.bubble_count(kind) - 1  # Enough wrong answers for the bubbles?


# Changes to another screen with a short fade, for example go_to("main_menu").
func go_to(screen_name: String) -> void:
	if _changing:  # A change is already running ...
		return  # ... so ignore this one.
	_changing = true  # Block further changes.
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP  # Block taps during the fade.
	var tween := create_tween()  # Fade out, swap, fade in.
	tween.tween_property(_veil, "color:a", 1.0, FADE_SECONDS)  # Cover the screen.
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(SCREEN_PATH % screen_name))  # Swap the screen.
	tween.tween_property(_veil, "color:a", 0.0, FADE_SECONDS + 0.06)  # Uncover the new screen.
	tween.tween_callback(_on_change_done)  # Allow taps again.


# Runs when a screen change has finished: allows taps and changes again.
func _on_change_done() -> void:
	_changing = false  # Changes allowed again.
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through again.


# Buzzes the phone briefly, if the device can and Vibration is on in Settings.
func vibrate() -> void:
	if Save.settings.vibration:  # Vibration switched on ...
		Input.vibrate_handheld(120)  # ... buzz for 120 milliseconds (phones only).


# Saves and closes the game. Called by the Exit button.
func quit_game() -> void:
	Save.save_now()  # Make sure nothing is lost.
	get_tree().quit()  # Close the app.
