# Composes DiviRush's original chiptune sound effects in code (D-009) and saves them as WAV files:
#   assets/audio/sfx/*.wav  tap, correct, wrong, time-up, star and pop sounds
# The music is no longer made here: it is free CC0 music, made into OGG files by
# tools/convert_music.sh (D-018).
# Run from the project folder with:
#   godot --headless --script res://tools/build_audio.gd
extends SceneTree  # A SceneTree script runs on its own, without opening a scene.

const RATE := 22050  # Samples per second; enough for chiptune and keeps files small.
const SFX_DIR := "res://assets/audio/sfx/"  # Where sound effects go.

var _noise := RandomNumberGenerator.new()  # Random numbers for the pop's noise.


# Runs once when the tool starts: makes every sound, then quits.
func _init() -> void:
	_noise.seed = 9  # Same noise every time the tool runs.
	_save_wav(SFX_DIR + "tap.wav", _sfx_tap())  # Button tap.
	_save_wav(SFX_DIR + "correct.wav", _sfx_correct())  # Correct answer.
	_save_wav(SFX_DIR + "wrong.wav", _sfx_wrong())  # Wrong answer.
	_save_wav(SFX_DIR + "time_up.wav", _sfx_time_up())  # Timer ran out.
	_save_wav(SFX_DIR + "star.wav", _sfx_star())  # A Star fills in.
	_save_wav(SFX_DIR + "pop.wav", _sfx_pop())  # A bubble pops.
	quit()  # Close the tool when done.


# ---------- Sound effects ----------

# A short high blip for button taps.
func _sfx_tap() -> PackedFloat32Array:
	var buffer := _silence(0.08)  # 80 milliseconds.
	_note(buffer, "pulse50", 81, 0.0, 0.06, 0.25)  # One short A5 blip.
	return buffer  # The finished sound.


# Two rising notes for a correct answer.
func _sfx_correct() -> PackedFloat32Array:
	var buffer := _silence(0.32)  # About a third of a second.
	_note(buffer, "pulse25", 84, 0.0, 0.09, 0.28)  # C6.
	_note(buffer, "pulse25", 91, 0.08, 0.2, 0.28)  # G6, higher and happy.
	return buffer  # The finished sound.


# A low falling buzz for a wrong answer.
func _sfx_wrong() -> PackedFloat32Array:
	var buffer := _silence(0.35)  # About a third of a second.
	_slide(buffer, "pulse50", 220.0, 140.0, 0.0, 0.32, 0.25)  # Low note that slides down.
	return buffer  # The finished sound.


# Three falling notes when the timer runs out.
func _sfx_time_up() -> PackedFloat32Array:
	var buffer := _silence(0.6)  # Just over half a second.
	_note(buffer, "triangle", 79, 0.0, 0.15, 0.4)  # G5.
	_note(buffer, "triangle", 76, 0.16, 0.15, 0.4)  # E5.
	_note(buffer, "triangle", 72, 0.32, 0.25, 0.4)  # C5.
	return buffer  # The finished sound.


# A quick sparkly run for each Star that fills in.
func _sfx_star() -> PackedFloat32Array:
	var buffer := _silence(0.45)  # Under half a second.
	var notes := [84, 88, 91, 96]  # C6, E6, G6, C7.
	for i in range(notes.size()):  # Each note, quickly one after another.
		_note(buffer, "pulse25", notes[i], i * 0.05, 0.2, 0.18)  # Bright, overlapping notes.
	return buffer  # The finished sound.


# A soft pop when a bubble bursts.
func _sfx_pop() -> PackedFloat32Array:
	var buffer := _silence(0.12)  # 120 milliseconds.
	_slide(buffer, "sine", 900.0, 300.0, 0.0, 0.08, 0.35)  # A quick falling "bloop".
	_noise_burst(buffer, 0.0, 0.03, 0.15)  # A tiny burst of noise for the snap.
	return buffer  # The finished sound.


# ---------- Building blocks ----------

# Returns an empty (silent) sound of the given length in seconds.
func _silence(seconds: float) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()  # Empty list of samples.
	buffer.resize(int(ceil(seconds * RATE)))  # One sample per 1/22050 second, all 0.
	return buffer  # Hand it back.


# Turns a MIDI note number into a frequency in Hz (69 = A4 = 440 Hz).
func _freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)  # Each semitone multiplies by the 12th root of 2.


# One sample of a wave shape at a given phase (0 to 1).
func _wave(shape: String, phase: float) -> float:
	match shape:  # Pick the shape.
		"pulse25":  # Thin square wave, the classic chiptune lead.
			return 1.0 if phase < 0.25 else -1.0  # High for a quarter, low for the rest.
		"pulse50":  # Full square wave.
			return 1.0 if phase < 0.5 else -1.0  # High for half, low for half.
		"triangle":  # Soft triangle wave, like an old game's bass.
			return 4.0 * absf(phase - 0.5) - 1.0  # Rises and falls in straight lines.
		_:  # Smooth sine wave.
			return sin(TAU * phase)  # The purest tone.


# Volume shape of a note: quick rise, gentle fall, quick fade at the end so there is no click.
func _envelope(t: float, length: float) -> float:
	var attack := minf(0.006, length * 0.2)  # Very short rise.
	var release := minf(0.03, length * 0.3)  # Short fade at the end.
	if t < attack:  # Rising part.
		return t / attack  # 0 to 1.
	if t > length - release:  # Fading part.
		return maxf(0.0, (length - t) / release) * 0.8  # Down to 0.
	return 1.0 - 0.2 * (t - attack) / maxf(length, 0.001)  # Slowly settles from 1.0 to 0.8.


# Adds one note to the buffer: shape, MIDI note, start and length in seconds, loudness 0-1.
func _note(buffer: PackedFloat32Array, shape: String, midi: float, start: float, length: float, volume: float) -> void:
	_slide(buffer, shape, _freq(midi), _freq(midi), start, length, volume)  # A note is a slide that does not move.


# Adds a tone that glides from one frequency to another.
func _slide(buffer: PackedFloat32Array, shape: String, from_hz: float, to_hz: float, start: float, length: float, volume: float) -> void:
	var first := int(start * RATE)  # First sample of the tone.
	var count := int(length * RATE)  # How many samples it lasts.
	var phase := 0.0  # Where we are inside one wave cycle.
	for i in range(count):  # Each sample of the tone.
		var index := first + i  # Its place in the buffer.
		if index >= buffer.size():  # Past the end of the sound ...
			break  # ... so stop.
		var t := float(i) / RATE  # Seconds since the tone started.
		var hz := lerpf(from_hz, to_hz, t / maxf(length, 0.001))  # Frequency at this moment.
		phase = fmod(phase + hz / RATE, 1.0)  # Move along the wave.
		buffer[index] += _wave(shape, phase) * _envelope(t, length) * volume  # Mix it in.


# Adds a burst of noise (used for the pop snap).
func _noise_burst(buffer: PackedFloat32Array, start: float, length: float, volume: float) -> void:
	var first := int(start * RATE)  # First sample.
	var count := int(length * RATE)  # How many samples.
	for i in range(count):  # Each sample.
		var index := first + i  # Its place in the buffer.
		if index >= buffer.size():  # Past the end ...
			break  # ... so stop.
		var fade := 1.0 - float(i) / count  # Fades out over the burst.
		buffer[index] += _noise.randf_range(-1.0, 1.0) * fade * fade * volume  # Random hiss, fading fast.


# Saves samples as a 16-bit mono WAV file.
func _save_wav(path: String, samples: PackedFloat32Array) -> void:
	var data := PackedByteArray()  # The sound data in bytes.
	data.resize(samples.size() * 2)  # Two bytes per sample.
	for i in range(samples.size()):  # Each sample ...
		var value := clampf(tanh(samples[i] * 1.2), -1.0, 1.0)  # ... softly limited so loud parts do not crackle,
		data.encode_s16(i * 2, int(value * 32000.0))  # ... stored as a 16-bit number.
	var out := PackedByteArray()  # The whole file.
	out.append_array("RIFF".to_ascii_buffer())  # File type marker.
	out.append_array(_u32(4 + 24 + 8 + data.size()))  # Size of everything after this field.
	out.append_array("WAVE".to_ascii_buffer())  # It is a WAVE file.
	out.append_array("fmt ".to_ascii_buffer())  # Format chunk marker.
	out.append_array(_u32(16))  # Format chunk size.
	out.append_array(_u16(1))  # 1 = plain PCM sound.
	out.append_array(_u16(1))  # 1 channel (mono).
	out.append_array(_u32(RATE))  # Samples per second.
	out.append_array(_u32(RATE * 2))  # Bytes per second.
	out.append_array(_u16(2))  # Bytes per sample.
	out.append_array(_u16(16))  # Bits per sample.
	out.append_array("data".to_ascii_buffer())  # Data chunk marker.
	out.append_array(_u32(data.size()))  # Data size.
	out.append_array(data)  # The sound itself.
	var file := FileAccess.open(path, FileAccess.WRITE)  # Open the file.
	if file == null:  # It could not be opened ...
		push_error("Could not write " + path)  # ... so say so.
		return  # Stop here.
	file.store_buffer(out)  # Write all bytes.
	print("saved %s (%.1f s)" % [path, float(samples.size()) / RATE])  # Report the file and its length.


# Encodes a whole number as 4 little-endian bytes.
func _u32(value: int) -> PackedByteArray:
	var bytes := PackedByteArray()  # Four empty bytes.
	bytes.resize(4)  # Make room.
	bytes.encode_u32(0, value)  # Write the number.
	return bytes  # Hand them back.


# Encodes a whole number as 2 little-endian bytes.
func _u16(value: int) -> PackedByteArray:
	var bytes := PackedByteArray()  # Two empty bytes.
	bytes.resize(2)  # Make room.
	bytes.encode_u16(0, value)  # Write the number.
	return bytes  # Hand them back.
