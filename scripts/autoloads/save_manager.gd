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
# `lead` and `tail` are the right answers in a row at the start and at the end of the Level, and
# `total` its number of items, for the streak that carries across Levels (D-031); -1 skips it.
# Returns which bests are new, plus "new_trophies", the ids of the Trophies just earned.
# Called by the Play screen at the end of a Level.
func record_result(episode: int, difficulty: int, level: int, stars: int, score: int, time: float, correct: int = 0, streak: int = 0, lead: int = -1, tail: int = -1, total: int = 0) -> Dictionary:
	var passed_before := progress.is_passed(episode, difficulty, level)  # Was this Level passed before this play?
	var flags := progress.record(episode, difficulty, level, stars, score, time)  # Update the bests.
	records.add_play(correct, streak, time)  # Add the play to the records.
	records.note_day(Time.get_date_string_from_system())  # Count today, once, for "Three Days" (D-031).
	records.note_result(Progress.level_key(episode, difficulty, level), stars >= 1, passed_before)  # Passed means at least one Star; for "Try Again".
	if lead >= 0:  # The Play screen gave the streaks ...
		records.carry_streak(lead, tail, correct, total)  # ... so carry the streak on, for "Super Streak".
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


# Picks the Featured Trophy from the Profile screen and saves it (D-031). Only an earned Trophy, or
# "" for None, can be picked.
func set_featured(id: String) -> void:
	if id == "" or records.has_trophy(id):  # None, or an earned Trophy ...
		profile.featured = id  # ... is kept,
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
