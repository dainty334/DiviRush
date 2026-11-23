# Tests for the game's sound effects (D-019): all six are recorded CC0 sounds from Kenney's
# Interface Sounds, not the old code-made square-wave beeps.
extends GutTest  # GUT gives this script its assert_* checks.


# Every sound effect is a recorded WAV at 44100 samples per second; the old code-made ones were 22050.
func test_sound_effects_are_the_recorded_ones() -> void:
	for sound: String in Audio.SFX:  # Tap, correct, wrong, time-up, Star and pop ...
		var stream := load(Audio.SFX[sound]) as AudioStreamWAV  # ... loads as a WAV sound,
		assert_not_null(stream, sound)  # ... which exists,
		assert_eq(stream.mix_rate, 44100, sound)  # ... and is a recording, not a code-made beep.


# Every sound effect is short, so it never runs on into the next item or screen.
func test_sound_effects_are_short() -> void:
	for sound: String in Audio.SFX:  # Each sound effect ...
		assert_lt(load(Audio.SFX[sound]).get_length(), 0.6, sound)  # ... lasts under 0.6 s.


# The old tool that made the beeps is gone, so running it cannot overwrite the recorded sounds.
func test_old_sound_tool_is_gone() -> void:
	assert_false(FileAccess.file_exists("res://tools/build_audio.gd"))  # No code-made sounds any more.
