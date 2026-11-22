# Tests that progress and settings are saved on the device and survive a restart.
extends GutTest  # GUT gives this script its assert_* checks.

const TEST_PATH := "user://test_save.cfg"  # A separate file, so tests never touch the real save.
const EASY := Difficulty.Kind.EASY  # Short name for Easy.


# Runs after every test: delete the test file so each test starts clean.
func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):  # Only if the test made the file.
		DirAccess.remove_absolute(TEST_PATH)  # Delete it.


# Saved bests and settings come back the same in new objects, as after a restart.
func test_progress_and_settings_survive_a_restart() -> void:
	var progress := Progress.new()  # Progress before the "restart".
	progress.record(1, EASY, 1, 2, 180, 62.5)  # A passed play to save.
	var settings := {"music": false, "sfx": true, "vibration": false}  # Settings to save.
	var error := SaveStore.new(TEST_PATH).save(progress, settings)  # Write the file.
	assert_eq(error, OK)  # Saving worked.

	var loaded_progress := Progress.new()  # New, empty objects, as after a restart.
	var loaded_settings := SaveStore.default_settings()  # Start from the defaults.
	SaveStore.new(TEST_PATH).load_into(loaded_progress, loaded_settings)  # Read the file back.
	var best := loaded_progress.best(1, EASY, 1)  # The loaded bests for Level 1.
	assert_eq(best.stars, 2)  # Stars came back.
	assert_eq(best.score, 180)  # Score came back.
	assert_almost_eq(best.time, 62.5, 0.001)  # Time came back.
	assert_true(loaded_progress.is_level_open(1, EASY, 2))  # Unlocking came back too.
	assert_eq(loaded_settings, settings)  # Settings came back.


# Medium and Hard bests are saved under their own keys and come back separately from Easy.
func test_medium_and_hard_bests_survive_a_restart() -> void:
	var progress := Progress.new()  # Progress before the "restart".
	progress.record(1, EASY, 1, 3, 250, 40.0)  # Easy Level 1.
	progress.record(1, Difficulty.Kind.MEDIUM, 1, 1, 120, 70.0)  # Medium Level 1.
	progress.record(1, Difficulty.Kind.HARD, 1, 2, 160, 55.0)  # Hard Level 1.
	assert_eq(SaveStore.new(TEST_PATH).save(progress, SaveStore.default_settings()), OK)  # Write the file.
	var loaded := Progress.new()  # New, empty progress, as after a restart.
	SaveStore.new(TEST_PATH).load_into(loaded, SaveStore.default_settings())  # Read the file back.
	assert_eq(loaded.best(1, EASY, 1).stars, 3)  # Easy came back.
	assert_eq(loaded.best(1, Difficulty.Kind.MEDIUM, 1).stars, 1)  # Medium came back on its own.
	assert_eq(loaded.best(1, Difficulty.Kind.HARD, 1).stars, 2)  # Hard came back on its own.


# With no save file yet, loading keeps the defaults and does not crash.
func test_missing_file_keeps_defaults() -> void:
	var progress := Progress.new()  # Empty progress.
	var settings := SaveStore.default_settings()  # Default settings.
	SaveStore.new(TEST_PATH).load_into(progress, settings)  # No file exists yet.
	assert_eq(settings, {"music": true, "sfx": true, "vibration": true})  # Everything on by default.
	assert_false(progress.is_level_open(1, EASY, 2))  # Only Level 1 is open.
