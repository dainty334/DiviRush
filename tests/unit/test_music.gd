# Tests for the game's music (D-018): the three CC0 tracks are OGG files, the menu and play
# tracks repeat by themselves, and the win jingle plays once.
extends GutTest  # GUT gives this script its assert_* checks.


# Every music track is one of the new OGG files, so the old code-made WAV music is gone.
func test_music_tracks_are_ogg_files() -> void:
	for track: String in Audio.MUSIC:  # Menu, play and win ...
		assert_true(Audio.MUSIC[track].ends_with(".ogg"), track)  # ... point at an OGG file,
		assert_is(load(Audio.MUSIC[track]), AudioStreamOggVorbis, track)  # ... which loads as OGG music.


# The menu and play tracks repeat without stopping; the win jingle plays once and ends,
# so the Level end screen can go back to the menu music after it.
func test_loops_repeat_and_the_jingle_plays_once() -> void:
	assert_true((load(Audio.MUSIC["menu"]) as AudioStreamOggVorbis).loop)  # Menu music repeats.
	assert_true((load(Audio.MUSIC["play"]) as AudioStreamOggVorbis).loop)  # Play music repeats.
	assert_false((load(Audio.MUSIC["win"]) as AudioStreamOggVorbis).loop)  # The jingle plays once.


# The right files are in place: a long calm menu loop, a shorter play loop and a short jingle.
func test_track_lengths() -> void:
	assert_gt(load(Audio.MUSIC["menu"]).get_length(), 60.0)  # "Home" loop: about 84 s.
	assert_gt(load(Audio.MUSIC["play"]).get_length(), 30.0)  # "Picnic" loop: about 35 s.
	assert_lt(load(Audio.MUSIC["win"]).get_length(), 3.0)  # Saxophone jingle: under 1 s.
