# Reads and writes the save file on the device: Settings switches and each Level's bests (D-010).
# The file is a Godot ConfigFile, plain text in sections, at user://save.cfg. There is no cloud save.
class_name SaveStore  # Lets the Save autoload and tests use SaveStore.
extends RefCounted  # A light object that frees itself when no longer used.

const DEFAULT_PATH := "user://save.cfg"  # The real save file (user:// is the app's own folder).
const SETTINGS_SECTION := "settings"  # Section name for the Settings switches.
const META_SECTION := "meta"  # Section name for facts about the file itself.
const VERSION := 1  # Save layout version, so a later game version can update old saves.

var path: String  # Which file this store reads and writes.


# Makes a store for one file. Tests pass their own path so they never touch the real save.
func _init(file_path: String = DEFAULT_PATH) -> void:
	path = file_path  # Remember the file.


# Returns the Settings a new player starts with: music, sound effects and vibration all on.
static func default_settings() -> Dictionary:
	return {"music": true, "sfx": true, "vibration": true}  # Everything on at first.


# Writes all bests and Settings to the file. Returns OK, or an error code if writing failed.
func save(progress: Progress, settings: Dictionary) -> Error:
	var config := ConfigFile.new()  # An empty file in memory.
	config.set_value(META_SECTION, "version", VERSION)  # Mark which save layout this is.
	for key in settings:  # Each Setting ...
		config.set_value(SETTINGS_SECTION, key, settings[key])  # ... goes into the settings section.
	for level_key in progress.bests:  # Each played Level ...
		var best: Dictionary = progress.bests[level_key]  # ... has its bests ...
		config.set_value(level_key, "stars", best.stars)  # ... best Stars,
		config.set_value(level_key, "score", best.score)  # ... best score,
		config.set_value(level_key, "time", best.time)  # ... and best time.
	return config.save(path)  # Write the file to the device.


# Reads the file into the given progress and settings. A missing or broken file keeps the defaults.
func load_into(progress: Progress, settings: Dictionary) -> void:
	var config := ConfigFile.new()  # An empty file in memory.
	if config.load(path) != OK:  # No save yet, or it could not be read ...
		return  # ... so keep the defaults.
	for section in config.get_sections():  # Each section in the file.
		if section == META_SECTION:  # Facts about the file, not game data ...
			continue  # ... so skip it (version 1 needs no update step).
		if section == SETTINGS_SECTION:  # The Settings section ...
			for key in settings:  # ... sets each known switch,
				settings[key] = bool(config.get_value(section, key, settings[key]))  # ... keeping the default if missing.
		else:  # Any other section is one Level's bests.
			progress.bests[section] = {  # Store them under the Level key.
				"stars": int(config.get_value(section, "stars", 0)),  # Best Stars, or 0.
				"score": int(config.get_value(section, "score", 0)),  # Best score, or 0.
				"time": float(config.get_value(section, "time", Progress.NO_TIME)),  # Best time, or none.
			}  # End of the list.
