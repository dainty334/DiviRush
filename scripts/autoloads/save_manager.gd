# The "Save" autoload: holds the learner's progress and Settings for the whole game,
# and writes them to user://save.cfg (D-010) whenever they change.
extends Node  # Autoloads are nodes that live for the whole game.

signal setting_changed(key: String, value: bool)  # Sent when a Settings switch changes, so Audio can react.

var progress := Progress.new()  # Best results and unlocking.
var settings: Dictionary = SaveStore.default_settings()  # Music, sound effects and vibration switches.
var _store := SaveStore.new()  # Reads and writes the real save file.


# Runs once when the game starts: loads the save file, if there is one.
func _ready() -> void:
	_store.load_into(progress, settings)  # A missing file keeps the defaults.


# Saves one finished play and returns which bests are new. Called by the Play screen at the end.
func record_result(episode: int, difficulty: int, level: int, stars: int, score: int, time: float) -> Dictionary:
	var flags := progress.record(episode, difficulty, level, stars, score, time)  # Update the bests.
	save_now()  # Write them to the device straight away.
	return flags  # Tell the Level end screen what is new.


# Turns a Settings switch on or off and saves it. Called by the Settings screen.
func set_setting(key: String, on: bool) -> void:
	settings[key] = on  # Change the switch.
	save_now()  # Write it to the device.
	setting_changed.emit(key, on)  # Tell anyone listening (the Audio autoload).


# Writes everything to user://save.cfg, and reports a problem if writing fails.
func save_now() -> void:
	var error := _store.save(progress, settings)  # Try to write the file.
	if error != OK:  # Writing failed ...
		push_error("DiviRush could not save (error %d)" % error)  # ... so report it.


# Runs when the phone sends the app to the background: save, in case the app is closed there.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:  # The app was sent to the background ...
		save_now()  # ... so save now.
