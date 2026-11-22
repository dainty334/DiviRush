# Opens every screen in a real window and saves a screenshot of each to docs/screenshots/,
# for the manuscript (Chapter III). Progress is changed only in memory; the save file is not written.
# Run from the project folder (not headless, so the screens are drawn) with:
#   godot --path . --resolution 540x960 --script res://tools/capture_screens.gd
extends SceneTree  # A SceneTree script runs on its own, without opening a scene.

const OUT_DIR := "res://docs/screenshots/"  # Where the pictures go.
const SCREEN := "res://scenes/screens/%s.tscn"  # Screen scene paths.


# Runs once after the autoloads exist: starts the capture steps.
# This tool names no game classes in its own code (Progress, AnswerBubble ...), because Godot would
# compile them before the autoloads exist and the screens would break.
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))  # Make the folder if needed.
	_capture_all()  # Runs step by step, waiting between screens.


# Opens each screen, waits for its animations, and saves a picture.
func _capture_all() -> void:
	var save: Node = root.get_node("Save")  # The Save autoload.
	var game: Node = root.get_node("Game")  # The Game autoload.
	save.progress = load("res://scripts/rules/progress.gd").new()  # Fresh progress in memory only (loaded here, after the autoloads exist).
	save.progress.record(1, 0, 1, 3, 245, 48.2)  # Level 1 passed with 3 Stars.
	save.progress.record(1, 0, 2, 2, 198, 61.0)  # Level 2 passed with 2 Stars.
	await _shot("start_screen", "01_start_up_menu")  # Start-up menu.
	await _shot("main_menu", "02_main_menu")  # Main menu.
	await _shot("how_to_play", "03_how_to_play")  # Rules screen.
	await _shot("settings_screen", "04_settings")  # Settings.
	await _shot("episode_select", "05_episode_select")  # Episodes 2-4 locked.
	game.episode = 1  # Episode 1 chosen.
	await _shot("difficulty_select", "06_difficulty_select")  # Medium and Hard locked.
	game.difficulty = 0  # Easy chosen (0 = Difficulty.Kind.EASY).
	await _shot("level_select", "07_level_select")  # Levels 1-3 open, 4-5 locked.
	game.level = 3  # Level 3 chosen.
	await _shot("play_screen", "08_play")  # An item waiting for a tap.
	var play: Node = current_scene  # The Play screen.
	play._on_bubble_tapped(_bubble_with(play, true))  # Tap the correct bubble.
	await _wait(0.35)  # Let the sparkle play.
	_save_picture("09_play_correct")  # Correct-answer feedback.
	await _wait(1.6)  # Next item appears.
	play._on_bubble_tapped(_bubble_with(play, false))  # Tap a wrong bubble.
	await _wait(0.3)  # Let the shake play.
	_save_picture("10_play_wrong")  # Wrong-answer feedback.
	await _wait(1.6)  # Next item appears.
	play._time_left = 0.05  # Let the timer run out.
	await _wait(0.4)  # Time-out feedback shows.
	_save_picture("11_play_time_up")  # Time-out with the correct answer shown.
	save.progress.record(1, 0, 3, 2, 214, 58.4)  # Level 3's result, as the Play screen would save it.
	game.last_result = {"correct": 9, "total": 10, "stars": 2, "score": 214, "time": 58.4, "passed": true, "new_best": true}  # A passed play.
	await _shot("level_end", "12_level_end", 2.6)  # Stars filled and "New best!".
	await _capture_medium_and_hard(save, game)  # Medium and Hard screens with 4 bubbles.
	quit()  # Close when done.


# Opens Medium and then Hard, as a learner would by passing Easy and Medium Level 5,
# and saves their Difficulty select, Level select and Play screens (4 bubbles).
func _capture_medium_and_hard(save: Node, game: Node) -> void:
	for level in range(3, 6):  # Easy Levels 3 to 5 ...
		save.progress.record(1, 0, level, 2, 200, 60.0)  # ... passed (0 = EASY), which opens Medium.
	save.progress.record(1, 1, 1, 3, 230, 45.0)  # Medium Level 1 passed with 3 Stars.
	save.progress.record(1, 1, 2, 1, 150, 75.0)  # Medium Level 2 passed with 1 Star.
	await _shot("difficulty_select", "13_difficulty_select_medium_open")  # Medium open, Hard locked.
	game.difficulty = 1  # Medium chosen (1 = Difficulty.Kind.MEDIUM).
	await _shot("level_select", "14_level_select_medium")  # Medium Levels 1-3 open.
	game.level = 3  # Medium Level 3 (÷5) chosen.
	await _shot("play_screen", "15_play_medium")  # 4 bubbles with near wrong answers, 10 s timer.
	for level in range(3, 6):  # Medium Levels 3 to 5 ...
		save.progress.record(1, 1, level, 2, 180, 70.0)  # ... passed (1 = MEDIUM), which opens Hard.
	save.progress.record(1, 2, 1, 2, 170, 50.0)  # Hard Level 1 passed with 2 Stars.
	game.difficulty = 2  # Hard chosen (2 = Difficulty.Kind.HARD).
	await _shot("level_select", "16_level_select_hard")  # Hard Levels 1-2 open.
	game.level = 2  # Hard Level 2 (÷2) chosen.
	await _shot("play_screen", "17_play_hard")  # 4 bubbles with look-alike wrong answers, 7 s timer.


# Opens a screen, waits for it to settle, and saves its picture.
func _shot(screen: String, file_name: String, settle: float = 1.3) -> void:
	change_scene_to_file(SCREEN % screen)  # Open the screen.
	await _wait(settle)  # Let pop-in animations finish.
	_save_picture(file_name)  # Save the picture.


# Waits for some seconds.
func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout  # A one-time timer.


# Saves what the window shows now as a PNG.
func _save_picture(file_name: String) -> void:
	var image := root.get_texture().get_image()  # The drawn window.
	var path := OUT_DIR + file_name + ".png"  # File path.
	image.save_png(path)  # Save it.
	print("saved ", path, " ", image.get_size())  # Report it.


# Finds a bubble on the Play screen: the correct one, or a wrong one.
func _bubble_with(play: Node, correct: bool) -> Node:
	var answer: int = play._item.correct_answer()  # The right number now.
	for bubble in play._bubbles:  # Look at each bubble ...
		if (bubble.value == answer) == correct:  # ... right or wrong as asked ...
			return bubble  # ... and return it.
	return null  # Not found (should not happen).
