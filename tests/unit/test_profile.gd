# Tests for the learner's Profile (D-030): the Nickname rules, the Buddy choice, and saving both,
# with each Trophy's earned date, in save layout version 3.
extends GutTest  # GUT gives this script its assert_* checks.

const TEST_PATH := "user://test_profile.cfg"  # A separate file, so tests never touch the real save.


# Runs after every test: delete the test file so each test starts clean.
func after_each() -> void:
	if FileAccess.file_exists(TEST_PATH):  # Only if the test made the file.
		DirAccess.remove_absolute(TEST_PATH)  # Delete it.


# A Nickname keeps letters (also ñ and é), numbers and spaces, drops other signs, and stops at 12 characters.
func test_clean_keeps_letters_numbers_and_spaces() -> void:
	assert_eq(Profile.clean("Bea!"), "Bea")  # The "!" is dropped.
	assert_eq(Profile.clean("Niño 2"), "Niño 2")  # ñ, a space and a number stay.
	assert_eq(Profile.clean("<José>"), "José")  # Signs are dropped, é stays.
	assert_eq(Profile.clean("Abcdefghijklmnop"), "Abcdefghijkl")  # Only the first 12 characters stay.


# A Nickname is ready when it has 1 to 12 characters that are not all spaces.
func test_valid_nicknames() -> void:
	assert_false(Profile.is_valid(""))  # Nothing typed.
	assert_false(Profile.is_valid("   "))  # Only spaces.
	assert_true(Profile.is_valid("Bea"))  # A short nickname.
	assert_true(Profile.is_valid("Abcdefghijkl"))  # Exactly 12.
	assert_false(Profile.is_valid("Abcdefghijklm"))  # 13 is too long.
	assert_false(Profile.is_valid("Bea!"))  # A sign that is not allowed.


# A new Profile has no Nickname yet and the Buddy "Both", so Ana and Migo take turns.
func test_new_profile() -> void:
	var profile := Profile.new()  # A first-time player.
	assert_false(profile.has_nickname())  # No Nickname yet ...
	assert_eq(profile.buddy, "Both")  # ... and both mascots.
	assert_eq(profile.mascots(), ["Ana", "Migo"] as Array[String])  # They take turns.


# Each Buddy choice decides which mascots show.
func test_buddy_decides_the_mascots() -> void:
	var profile := Profile.new()  # A player.
	profile.buddy = "Ana"  # Only Ana ...
	assert_eq(profile.mascots(), ["Ana"] as Array[String])  # ... shows.
	profile.buddy = "Migo"  # Only Migo ...
	assert_eq(profile.mascots(), ["Migo"] as Array[String])  # ... shows.


# The Nickname, the Buddy and the Trophies' earned dates come back after a restart.
func test_profile_and_trophy_dates_survive_a_restart() -> void:
	var profile := Profile.new()  # The Profile before the "restart".
	profile.nickname = "Bea"  # Her Nickname.
	profile.buddy = "Migo"  # Her Buddy.
	var records := Records.new()  # Records with one dated Trophy.
	records.trophies.assign(["first_star"])  # "First Star" earned ...
	records.trophy_dates["first_star"] = "2026-11-24"  # ... on 24 November 2026.
	assert_eq(SaveStore.new(TEST_PATH).save(Progress.new(), SaveStore.default_settings(), records, profile), OK)  # Write the file.
	var loaded_profile := Profile.new()  # New, empty objects, as after a restart.
	var loaded_records := Records.new()  # Empty records.
	var loaded_progress := Progress.new()  # Empty progress.
	SaveStore.new(TEST_PATH).load_into(loaded_progress, SaveStore.default_settings(), loaded_records, loaded_profile)  # Read the file back.
	assert_eq(loaded_profile.nickname, "Bea")  # The Nickname came back.
	assert_eq(loaded_profile.buddy, "Migo")  # The Buddy came back.
	assert_eq(loaded_records.earned_date("first_star"), "2026-11-24")  # The date came back.
	assert_eq(loaded_progress.bests.size(), 0)  # The profile section is not read as a Level.


# A save from before version 3 has no Profile: it loads with no Nickname, so the Welcome screen shows once.
func test_older_save_has_no_nickname() -> void:
	var config := ConfigFile.new()  # A version 2 file, written by hand.
	config.set_value("meta", "version", 2)  # Its version.
	config.set_value("records", "trophies", ["first_star"])  # A Trophy with no date.
	config.save(TEST_PATH)  # Write it.
	var profile := Profile.new()  # Empty Profile.
	var records := Records.new()  # Empty records.
	SaveStore.new(TEST_PATH).load_into(Progress.new(), SaveStore.default_settings(), records, profile)  # Read it.
	assert_false(profile.has_nickname())  # No Nickname yet.
	assert_eq(profile.buddy, "Both")  # The default Buddy.
	assert_true(records.has_trophy("first_star"))  # The Trophy is kept ...
	assert_eq(records.earned_date("first_star"), "")  # ... with no date.


# A Buddy that is not Ana, Migo or Both in the file falls back to Both.
func test_unknown_buddy_falls_back_to_both() -> void:
	var config := ConfigFile.new()  # A file with a broken Buddy.
	config.set_value("profile", "nickname", "Bea")  # A Nickname.
	config.set_value("profile", "buddy", "Someone")  # Not a Buddy.
	config.save(TEST_PATH)  # Write it.
	var profile := Profile.new()  # Empty Profile.
	SaveStore.new(TEST_PATH).load_into(Progress.new(), SaveStore.default_settings(), null, profile)  # Read it.
	assert_eq(profile.nickname, "Bea")  # The Nickname is read.
	assert_eq(profile.buddy, "Both")  # The Buddy falls back.
