# The "Save" autoload: holds the learner's progress and Settings for the whole game,
# and writes them to user://save.cfg (D-010) whenever they change.
extends Node  # Autoloads are nodes that live for the whole game.

signal setting_changed(key: String, value: bool)  # Sent when a Settings switch changes, so Audio can react.

var progress := Progress.new()  # Best results and unlocking.
var settings: Dictionary = SaveStore.default_settings()  # Music, sound effects and vibration switches.
var records := Records.new()  # Game records for the Records tab, and the Trophies earned (D-023, D-030).
var profile := Profile.new()  # The learner's Nickname and Buddy (D-030).
var _store := SaveStore.new()  # Reads and writes the real save file; tests swap in their own file.


# Runs once when the game starts: loads the save file, if there is one.
func _ready() -> void:
	_store.load_into(progress, settings, records, profile)  # A missing file keeps the defaults.
	Trophies.award(progress, records)  # Give, quietly, any Trophies that bests saved before Trophies existed already earn (D-023).


# Saves one finished play: its bests, its game records, and any Trophies it earns (D-023).
# Returns which bests are new, plus "new_trophies", the ids of the Trophies just earned.
# Called by the Play screen at the end of a Level.
func record_result(episode: int, difficulty: int, level: int, stars: int, score: int, time: float, correct: int = 0, streak: int = 0) -> Dictionary:
	var flags := progress.record(episode, difficulty, level, stars, score, time)  # Update the bests.
	records.add_play(correct, streak, time)  # Add the play to the records.
	flags["new_trophies"] = Trophies.award(progress, records)  # Give any Trophies now earned.
	save_now()  # Write everything to the device straight away.
	return flags  # Tell the Level end screen what is new.


# Turns a Settings switch on or off and saves it. Called by the Settings screen.
func set_setting(key: String, on: bool) -> void:
	settings[key] = on  # Change the switch.
	save_now()  # Write it to the device.
	setting_changed.emit(key, on)  # Tell anyone listening (the Audio autoload).


# Keeps the Nickname and the Buddy from the Welcome screen and saves them (D-030).
func set_profile(nickname: String, buddy: String) -> void:
	profile.nickname = Profile.clean(nickname).strip_edges()  # The Nickname, without spaces at the ends.
	profile.buddy = buddy if Profile.BUDDIES.has(buddy) else Profile.BOTH  # A known Buddy, or Both.
	save_now()  # Write it to the device.


# Changes the Nickname from the Profile screen and saves it. A Nickname that breaks the rules is ignored.
func set_nickname(nickname: String) -> void:
	if Profile.is_valid(nickname):  # 1 to 12 allowed characters ...
		profile.nickname = nickname.strip_edges()  # ... kept without spaces at the ends,
		save_now()  # ... and written to the device.


# Changes the Buddy from the Profile screen and saves it.
func set_buddy(buddy: String) -> void:
	if Profile.BUDDIES.has(buddy):  # Ana, Migo or Both ...
		profile.buddy = buddy  # ... is kept,
		save_now()  # ... and written to the device.


# Writes everything to user://save.cfg, and reports a problem if writing fails.
func save_now() -> void:
	var error := _store.save(progress, settings, records, profile)  # Try to write the file.
	if error != OK:  # Writing failed ...
		push_error("DiviRush could not save (error %d)" % error)  # ... so report it.


# Runs when the phone sends the app to the background: save, in case the app is closed there.
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED:  # The app was sent to the background ...
		save_now()  # ... so save now.
