# Reads and writes the save file on the device: Settings switches and each Level's bests (D-010).
# The file is a Godot ConfigFile, plain text in sections, at user://save.cfg. There is no cloud save.
class_name SaveStore  # Lets the Save autoload and tests use SaveStore.
extends RefCounted  # A light object that frees itself when no longer used.

const DEFAULT_PATH := "user://save.cfg"  # The real save file (user:// is the app's own folder).
const SETTINGS_SECTION := "settings"  # Section name for the Settings switches.
const META_SECTION := "meta"  # Section name for facts about the file itself.
const RECORDS_SECTION := "records"  # Section name for the game records and earned Trophies (D-023).
const PROFILE_SECTION := "profile"  # Section name for the Nickname and the Buddy (D-030).
const VERSION := 3  # Save layout version: 2 added the records, 3 the profile and Trophy dates. Older files still load.

var path: String  # Which file this store reads and writes.


# Makes a store for one file. Tests pass their own path so they never touch the real save.
func _init(file_path: String = DEFAULT_PATH) -> void:
	path = file_path  # Remember the file.


# Returns the Settings a new player starts with: music, sound effects and vibration all on.
static func default_settings() -> Dictionary:
	return {"music": true, "sfx": true, "vibration": true}  # Everything on at first.


# Writes all bests, Settings and (when given) the game records and the Profile to the file.
# Returns OK, or an error code if writing failed.
func save(progress: Progress, settings: Dictionary, records: Records = null, profile: Profile = null) -> Error:
	var config := ConfigFile.new()  # An empty file in memory.
	config.set_value(META_SECTION, "version", VERSION)  # Mark which save layout this is.
	if profile != null:  # A Profile was given ...
		config.set_value(PROFILE_SECTION, "nickname", profile.nickname)  # ... the Nickname,
		config.set_value(PROFILE_SECTION, "buddy", profile.buddy)  # ... and the Buddy.
	if records != null:  # Records were given ...
		config.set_value(RECORDS_SECTION, "levels_played", records.levels_played)  # ... Levels played,
		config.set_value(RECORDS_SECTION, "correct_total", records.correct_total)  # ... correct answers,
		config.set_value(RECORDS_SECTION, "best_streak", records.best_streak)  # ... best streak,
		config.set_value(RECORDS_SECTION, "seconds_played", records.seconds_played)  # ... time played,
		config.set_value(RECORDS_SECTION, "trophies", records.trophies)  # ... the Trophies earned,
		config.set_value(RECORDS_SECTION, "trophy_dates", records.trophy_dates)  # ... and the day each was earned (D-030).
	for key in settings:  # Each Setting ...
		config.set_value(SETTINGS_SECTION, key, settings[key])  # ... goes into the settings section.
	for level_key in progress.bests:  # Each played Level ...
		var best: Dictionary = progress.bests[level_key]  # ... has its bests ...
		config.set_value(level_key, "stars", best.stars)  # ... best Stars,
		config.set_value(level_key, "score", best.score)  # ... best score,
		config.set_value(level_key, "time", best.time)  # ... and best time.
	return config.save(path)  # Write the file to the device.


# Reads the file into the given progress, settings and (when given) records and Profile.
# A missing or broken file keeps the defaults.
func load_into(progress: Progress, settings: Dictionary, records: Records = null, profile: Profile = null) -> void:
	var config := ConfigFile.new()  # An empty file in memory.
	if config.load(path) != OK:  # No save yet, or it could not be read ...
		return  # ... so keep the defaults.
	for section in config.get_sections():  # Each section in the file.
		if section == META_SECTION:  # Facts about the file, not game data ...
			continue  # ... so skip it (older versions need no update step).
		if section == PROFILE_SECTION:  # The Nickname and the Buddy, not a Level ...
			if profile != null:  # ... read them when asked,
				profile.nickname = Profile.clean(str(config.get_value(section, "nickname", "")))  # ... the Nickname, with only allowed characters,
				var buddy := str(config.get_value(section, "buddy", Profile.BOTH))  # ... and the Buddy,
				profile.buddy = buddy if Profile.BUDDIES.has(buddy) else Profile.BOTH  # ... or Both if it is not a known Buddy.
			continue  # Never read it as a Level's bests.
		if section == RECORDS_SECTION:  # The game records, not a Level ...
			if records != null:  # ... read them when asked,
				records.levels_played = int(config.get_value(section, "levels_played", 0))  # ... Levels played,
				records.correct_total = int(config.get_value(section, "correct_total", 0))  # ... correct answers,
				records.best_streak = int(config.get_value(section, "best_streak", 0))  # ... best streak,
				records.seconds_played = float(config.get_value(section, "seconds_played", 0.0))  # ... time played,
				records.trophies.assign(config.get_value(section, "trophies", []))  # ... the Trophies earned,
				records.trophy_dates = config.get_value(section, "trophy_dates", {})  # ... and their days, none in older files (D-030).
			continue  # Never read it as a Level's bests.
		if section == SETTINGS_SECTION:  # The Settings section ...
			for key in settings:  # ... sets each known switch,
				settings[key] = bool(config.get_value(section, key, settings[key]))  # ... keeping the default if missing.
		else:  # Any other section is one Level's bests.
			progress.bests[section] = {  # Store them under the Level key.
				"stars": int(config.get_value(section, "stars", 0)),  # Best Stars, or 0.
				"score": int(config.get_value(section, "score", 0)),  # Best score, or 0.
				"time": float(config.get_value(section, "time", Progress.NO_TIME)),  # Best time, or none.
			}  # End of the list.
