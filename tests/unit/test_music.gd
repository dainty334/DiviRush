# Tests for the game's music (D-018, D-020): every track is an OGG file, the loops repeat and the
# win jingle plays once, and each area of the game and each Episode has its own track.
extends GutTest  # GUT gives this script its assert_* checks.

const LOOPS := ["menu", "select", "play_1", "play_2", "play_3", "play_4"]  # Every track that repeats.
const SCREEN := "res://scenes/screens/%s.tscn"  # Screen scene paths.


# Every music track is an OGG file, so the old code-made WAV music is gone.
func test_music_tracks_are_ogg_files() -> void:
	for track: String in Audio.MUSIC:  # Every track ...
		assert_true(Audio.MUSIC[track].ends_with(".ogg"), track)  # ... points at an OGG file,
		assert_is(load(Audio.MUSIC[track]), AudioStreamOggVorbis, track)  # ... which loads as OGG music.


# The area and Episode tracks repeat without stopping; the win jingle plays once and ends,
# so the Level end screen can go on to the selection music after it.
func test_loops_repeat_and_the_jingle_plays_once() -> void:
	for track: String in LOOPS:  # Each looping track ...
		assert_true((load(Audio.MUSIC[track]) as AudioStreamOggVorbis).loop, track)  # ... repeats.
	assert_false((load(Audio.MUSIC["win"]) as AudioStreamOggVorbis).loop)  # The jingle plays once.


# No two areas or Episodes share a music file, so the music does not repeat across the game (D-020).
func test_every_area_and_episode_has_its_own_track() -> void:
	var files := {}  # Music files seen so far.
	for track: String in LOOPS:  # Each looping track ...
		files[Audio.MUSIC[track]] = true  # ... adds its file.
	assert_eq(files.size(), LOOPS.size())  # Six tracks, six different files.


# The right files are in place, checked by their length.
func test_track_lengths() -> void:
	assert_gt(load(Audio.MUSIC["menu"]).get_length(), 15.0)  # "Happy Clappy Loop": about 17 s.
	assert_gt(load(Audio.MUSIC["select"]).get_length(), 60.0)  # "Home": about 84 s.
	assert_gt(load(Audio.MUSIC["play_1"]).get_length(), 30.0)  # "Picnic": about 35 s.
	assert_gt(load(Audio.MUSIC["play_2"]).get_length(), 40.0)  # "Happy Vibes": about 45 s.
	assert_gt(load(Audio.MUSIC["play_3"]).get_length(), 100.0)  # "Cozy Puzzle In-Game 2": about 128 s.
	assert_gt(load(Audio.MUSIC["play_4"]).get_length(), 40.0)  # "Activity": about 50 s.
	assert_lt(load(Audio.MUSIC["win"]).get_length(), 3.0)  # Saxophone jingle: under 1 s.


# The Main menu area plays the menu track and the selection screens play the selection track (D-020).
func test_screens_play_their_area_music() -> void:
	Game.episode = 1  # Episode 1 chosen (Level select needs one).
	Game.difficulty = Difficulty.Kind.EASY  # Easy chosen.
	var cases := {  # Screen -> the track it should play.
		"start_screen": "menu", "main_menu": "menu", "how_to_play": "menu", "settings_screen": "menu",  # Main menu area.
		"episode_select": "select", "difficulty_select": "select", "level_select": "select",  # Selection area.
	}  # End of the list.
	for screen_name: String in cases:  # Each screen ...
		add_child_autofree(load(SCREEN % screen_name).instantiate())  # ... opens,
		assert_eq(Audio._current, cases[screen_name], screen_name)  # ... and plays its area's track.


# Each Episode plays its own track during play, so the Levels of different Episodes sound different.
func test_each_episode_plays_its_own_track() -> void:
	for episode in range(1, 5):  # Episodes 1 to 4 ...
		Game.episode = episode  # ... chosen,
		Game.difficulty = Difficulty.Kind.EASY  # ... on Easy,
		Game.level = 1  # ... Level 1,
		add_child_autofree(load(SCREEN % "play_screen").instantiate())  # ... the Play screen opens,
		assert_eq(Audio._current, "play_%d" % episode, "Episode %d" % episode)  # ... with that Episode's track.


# A passed Level plays the win jingle and then the selection track; a failed one plays the selection track.
func test_level_end_music() -> void:
	Game.last_result = {"correct": 9, "total": 10, "stars": 2, "score": 200, "time": 50.0, "passed": true, "new_best": false}  # A passed play.
	add_child_autofree(load(SCREEN % "level_end").instantiate())  # Level end opens.
	assert_eq(Audio._current, "win")  # The jingle plays ...
	assert_eq(Audio._after, "select")  # ... then the selection track.
	Game.last_result = {"correct": 5, "total": 10, "stars": 0, "score": 60, "time": 70.0, "passed": false, "new_best": false}  # A failed play.
	add_child_autofree(load(SCREEN % "level_end").instantiate())  # Level end opens again.
	assert_eq(Audio._current, "select")  # The selection track plays.
