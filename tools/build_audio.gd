# Composes DiviRush's original chiptune music and sound effects in code (D-009) and saves them as WAV files:
#   assets/audio/music/menu_loop.wav  calm loop for the menus
#   assets/audio/music/play_loop.wav  faster loop during play
#   assets/audio/music/win_jingle.wav short jingle on the Level end screen
#   assets/audio/sfx/*.wav            tap, correct, wrong, time-up, star and pop sounds
# The loops carry loop points inside the file, so Godot's importer makes them repeat by itself.
# Run from the project folder with:
#   godot --headless --script res://tools/build_audio.gd
extends SceneTree  # A SceneTree script runs on its own, without opening a scene.

const RATE := 22050  # Samples per second; enough for chiptune and keeps files small.
const MUSIC_DIR := "res://assets/audio/music/"  # Where music goes.
const SFX_DIR := "res://assets/audio/sfx/"  # Where sound effects go.

var _noise := RandomNumberGenerator.new()  # Random numbers for drum noise.


# Runs once when the tool starts: makes every sound, then quits.
func _init() -> void:
	_noise.seed = 9  # Same drums every time the tool runs.
	_save_wav(MUSIC_DIR + "menu_loop.wav", _menu_loop(), true)  # Calm menu loop.
	_save_wav(MUSIC_DIR + "play_loop.wav", _play_loop(), true)  # Faster play loop.
	_save_wav(MUSIC_DIR + "win_jingle.wav", _win_jingle(), false)  # Win jingle, plays once.
	_save_wav(SFX_DIR + "tap.wav", _sfx_tap(), false)  # Button tap.
	_save_wav(SFX_DIR + "correct.wav", _sfx_correct(), false)  # Correct answer.
	_save_wav(SFX_DIR + "wrong.wav", _sfx_wrong(), false)  # Wrong answer.
	_save_wav(SFX_DIR + "time_up.wav", _sfx_time_up(), false)  # Timer ran out.
	_save_wav(SFX_DIR + "star.wav", _sfx_star(), false)  # A Star fills in.
	_save_wav(SFX_DIR + "pop.wav", _sfx_pop(), false)  # A bubble pops.
	quit()  # Close the tool when done.


# ---------- Music ----------

# Calm menu loop: C major, 100 beats per minute, 8 bars (C, Am, F, G twice).
func _menu_loop() -> PackedFloat32Array:
	var beat := 60.0 / 100.0  # Seconds per beat at 100 BPM.
	var buffer := _silence(32 * beat)  # 8 bars x 4 beats.
	var roots := [48, 45, 41, 43, 48, 45, 41, 43]  # Chord root notes (MIDI numbers) per bar.
	var minor := [false, true, false, false, false, true, false, false]  # Which bars are minor chords.
	for bar in range(8):  # Each bar ...
		var start := bar * 4.0  # ... starts on this beat.
		_note(buffer, "triangle", roots[bar], start * beat, 2.0 * beat, 0.30)  # Bass root, half note.
		_note(buffer, "triangle", roots[bar] + 7, (start + 2.0) * beat, 2.0 * beat, 0.30)  # Bass fifth, half note.
		var shape := [0, 3, 7, 12] if minor[bar] else [0, 4, 7, 12]  # Chord notes above the root.
		var order := [0, 1, 2, 3, 2, 1, 2, 1]  # Up-and-down arpeggio pattern.
		for step in range(8):  # Eight soft eighth notes.
			_note(buffer, "pulse25", roots[bar] + 24 + shape[order[step]], (start + step * 0.5) * beat, 0.45 * beat, 0.07)  # Gentle arpeggio.
	var melody := [  # [note, start beat, length in beats]: an original, easy-going tune.
		[76, 0, 1], [79, 1, 1], [81, 2, 1.5], [79, 3.5, 0.5],  # Notes as [MIDI note, start beat, length in beats].
		[76, 4, 2], [72, 6, 2],  # Notes as [MIDI note, start beat, length in beats].
		[77, 8, 1], [81, 9, 1], [84, 10, 1.5], [81, 11.5, 0.5],  # Notes as [MIDI note, start beat, length in beats].
		[79, 12, 3],  # Notes as [MIDI note, start beat, length in beats].
		[76, 16, 1], [79, 17, 1], [84, 18, 1.5], [83, 19.5, 0.5],  # Notes as [MIDI note, start beat, length in beats].
		[81, 20, 2], [76, 22, 2],  # Notes as [MIDI note, start beat, length in beats].
		[77, 24, 1], [76, 25, 1], [74, 26, 1], [72, 27, 1],  # Notes as [MIDI note, start beat, length in beats].
		[74, 28, 2], [67, 30, 2],  # Notes as [MIDI note, start beat, length in beats].
	]  # End of the list.
	for n in melody:  # Each melody note ...
		_note(buffer, "triangle", n[0], n[1] * beat, n[2] * beat * 0.92, 0.22)  # ... played softly.
	return buffer  # The finished loop.


# Faster play loop: A minor, 140 beats per minute, 8 bars (Am, F, C, G twice) with drums.
func _play_loop() -> PackedFloat32Array:
	var beat := 60.0 / 140.0  # Seconds per beat at 140 BPM.
	var buffer := _silence(32 * beat)  # 8 bars x 4 beats.
	var roots := [45, 41, 48, 43, 45, 41, 48, 43]  # Chord root notes per bar.
	for bar in range(8):  # Each bar ...
		var start := bar * 4.0  # ... starts on this beat.
		for step in range(8):  # Driving eighth-note bass.
			var octave := 12 if step % 2 == 1 else 0  # Jump up an octave on every other note.
			_note(buffer, "pulse50", roots[bar] - 12 + octave, (start + step * 0.5) * beat, 0.4 * beat, 0.11)  # Bass note.
		for b in range(4):  # Drums on each beat ...
			_kick(buffer, (start + b) * beat)  # ... a kick drum,
			_hat(buffer, (start + b + 0.5) * beat)  # ... a hi-hat between beats,
			if b % 2 == 1:  # ... and on beats 2 and 4 ...
				_snare(buffer, (start + b) * beat)  # ... a snare.
	var phrase_a := [  # An original, bouncy lead for bars 1-3 (and 5-7).
		[81, 0, 0.5], [84, 0.5, 0.5], [88, 1, 0.5], [84, 1.5, 0.5], [81, 2, 1], [79, 3, 0.5], [81, 3.5, 0.5],  # Notes as [MIDI note, start beat, length in beats].
		[77, 4, 0.5], [81, 4.5, 0.5], [84, 5, 1], [81, 6, 0.5], [77, 6.5, 0.5], [76, 7, 1],  # Notes as [MIDI note, start beat, length in beats].
		[79, 8, 0.5], [84, 8.5, 0.5], [88, 9, 1], [86, 10, 0.5], [84, 10.5, 0.5], [79, 11, 1],  # Notes as [MIDI note, start beat, length in beats].
	]  # End of the list.
	var ending_1 := [[83, 12, 0.5], [86, 12.5, 0.5], [91, 13, 1.5], [86, 14.5, 0.5], [83, 15, 1]]  # Bar 4 lead.
	var ending_2 := [[79, 28, 0.5], [83, 28.5, 0.5], [86, 29, 0.5], [88, 29.5, 0.5], [86, 30, 1], [83, 31, 1]]  # Bar 8 lead, leads back to the start.
	var lead := []  # The full lead line.
	for n in phrase_a:  # Bars 1-3 ...
		lead.append(n)  # ... as written,
		lead.append([n[0], n[1] + 16, n[2]])  # ... and again in bars 5-7.
	lead.append_array(ending_1)  # Bar 4.
	lead.append_array(ending_2)  # Bar 8.
	for n in lead:  # Each lead note ...
		_note(buffer, "pulse25", n[0], n[1] * beat, n[2] * beat * 0.85, 0.10)  # ... played as a bright chiptune square.
	return buffer  # The finished loop.


# Short win jingle: a rising C major run that lands on a happy chord.
func _win_jingle() -> PackedFloat32Array:
	var beat := 60.0 / 150.0  # Seconds per beat at 150 BPM.
	var buffer := _silence(6.5 * beat + 0.5)  # Room for the notes plus a short fade.
	var run := [[72, 0, 0.5], [76, 0.5, 0.5], [79, 1, 0.5], [84, 1.5, 1.2], [79, 3, 0.5], [84, 3.5, 2.5]]  # Rising lead notes.
	for n in run:  # Each lead note ...
		_note(buffer, "pulse25", n[0], n[1] * beat, n[2] * beat, 0.14)  # ... as a bright square.
	for chord_note in [72, 76, 79]:  # The final happy chord ...
		_note(buffer, "triangle", chord_note, 3.5 * beat, 2.5 * beat, 0.12)  # ... held under the last note.
	_note(buffer, "triangle", 48, 0.0, 1.5 * beat, 0.3)  # Bass C.
	_note(buffer, "triangle", 43, 1.5 * beat, 2.0 * beat, 0.3)  # Bass G.
	_note(buffer, "triangle", 48, 3.5 * beat, 2.5 * beat, 0.3)  # Bass C again.
	return buffer  # The finished jingle.


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


# Adds a burst of noise (used for drums and the pop snap).
func _noise_burst(buffer: PackedFloat32Array, start: float, length: float, volume: float) -> void:
	var first := int(start * RATE)  # First sample.
	var count := int(length * RATE)  # How many samples.
	for i in range(count):  # Each sample.
		var index := first + i  # Its place in the buffer.
		if index >= buffer.size():  # Past the end ...
			break  # ... so stop.
		var fade := 1.0 - float(i) / count  # Fades out over the burst.
		buffer[index] += _noise.randf_range(-1.0, 1.0) * fade * fade * volume  # Random hiss, fading fast.


# Adds a kick drum: a sine that drops quickly in pitch.
func _kick(buffer: PackedFloat32Array, start: float) -> void:
	_slide(buffer, "sine", 150.0, 45.0, start, 0.12, 0.45)  # Deep thump.


# Adds a short, quiet hi-hat.
func _hat(buffer: PackedFloat32Array, start: float) -> void:
	_noise_burst(buffer, start, 0.03, 0.08)  # Tiny tick of noise.


# Adds a snare: a burst of noise with a little tone.
func _snare(buffer: PackedFloat32Array, start: float) -> void:
	_noise_burst(buffer, start, 0.12, 0.18)  # Noise crack.
	_slide(buffer, "triangle", 220.0, 180.0, start, 0.06, 0.12)  # Body of the drum.


# Saves samples as a 16-bit mono WAV file. If `loop` is true, adds a "smpl" chunk with loop points,
# which Godot's WAV importer reads ("Loop Mode: Detect From WAV"), so the music repeats by itself.
func _save_wav(path: String, samples: PackedFloat32Array, loop: bool) -> void:
	var data := PackedByteArray()  # The sound data in bytes.
	data.resize(samples.size() * 2)  # Two bytes per sample.
	for i in range(samples.size()):  # Each sample ...
		var value := clampf(tanh(samples[i] * 1.2), -1.0, 1.0)  # ... softly limited so loud parts do not crackle,
		data.encode_s16(i * 2, int(value * 32000.0))  # ... stored as a 16-bit number.
	var smpl := PackedByteArray()  # Optional loop chunk.
	if loop:  # Only loops get loop points.
		smpl = _smpl_chunk(samples.size())  # Loop the whole sound.
	var out := PackedByteArray()  # The whole file.
	out.append_array("RIFF".to_ascii_buffer())  # File type marker.
	out.append_array(_u32(4 + 24 + 8 + data.size() + smpl.size()))  # Size of everything after this field.
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
	out.append_array(smpl)  # Loop points (empty if none).
	var file := FileAccess.open(path, FileAccess.WRITE)  # Open the file.
	if file == null:  # It could not be opened ...
		push_error("Could not write " + path)  # ... so say so.
		return  # Stop here.
	file.store_buffer(out)  # Write all bytes.
	print("saved %s (%.1f s)" % [path, float(samples.size()) / RATE])  # Report the file and its length.


# Builds a WAV "smpl" chunk with one forward loop from the first to the last sample.
func _smpl_chunk(frame_count: int) -> PackedByteArray:
	var chunk := PackedByteArray()  # The chunk bytes.
	chunk.append_array("smpl".to_ascii_buffer())  # Chunk marker.
	chunk.append_array(_u32(36 + 24))  # Chunk size: header plus one loop.
	for value in [0, 0, int(1000000000.0 / RATE), 60, 0, 0, 0, 1, 0]:  # Maker, product, sample period, root note, tuning, SMPTE x2, 1 loop, extra data.
		chunk.append_array(_u32(value))  # Write each header field.
	for value in [0, 0, 0, frame_count, 0, 0]:  # Loop id, type 0 = forward, start, end, fraction, play forever.
		chunk.append_array(_u32(value))  # Write each loop field.
	return chunk  # Hand back the chunk.


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
