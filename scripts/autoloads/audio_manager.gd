# The "Audio" autoload: plays the music and sound effects for the whole game.
# Music plays on the "Music" bus and sound effects on the "SFX" bus, so each Settings switch
# mutes only its own bus (D-009).
extends Node  # Autoloads are nodes that live for the whole game.

const MUSIC := {  # Music tracks by name: free CC0 recordings, made into OGG files by tools/convert_audio.sh (D-018).
	"menu": "res://assets/audio/music/menu_loop.ogg",  # Calm loop for the menus: "Home" by heartade (piano, flute, strings).
	"play": "res://assets/audio/music/play_loop.ogg",  # Livelier loop during play: "Picnic" by heartade (saxophone, vibraphone, strings).
	"win": "res://assets/audio/music/win_jingle.ogg",  # Short saxophone jingle on a passed Level, by Kenney.
}  # End of the list.
const LOOPING := ["menu", "play"]  # Tracks that repeat.
const SFX := {  # Sound effects by name: recorded CC0 sounds from Kenney's Interface Sounds, made by tools/convert_audio.sh (D-019).
	"tap": "res://assets/audio/sfx/tap.wav",  # Button tap: a short, soft click.
	"correct": "res://assets/audio/sfx/correct.wav",  # Correct answer: a short rising sound.
	"wrong": "res://assets/audio/sfx/wrong.wav",  # Wrong answer: a low, gentle falling sound.
	"time_up": "res://assets/audio/sfx/time_up.wav",  # Timer ran out: a low falling swoosh.
	"star": "res://assets/audio/sfx/star.wav",  # A Star fills in: a glassy ring.
	"pop": "res://assets/audio/sfx/pop.wav",  # A bubble pops: a water drop.
}  # End of the list.
const SFX_PLAYERS := 6  # How many sound effects can play at the same time.
const FADE_SECONDS := 0.6  # Cross-fade time between music tracks.

var _streams: Dictionary = {}  # Loaded sounds by name.
var _music: Array[AudioStreamPlayer] = []  # Two music players, so one can fade in while the other fades out.
var _active := 0  # Which music player is playing now.
var _current := ""  # Name of the track playing now.
var _after := ""  # Track to start when a one-time track (the jingle) ends.
var _sfx: Array[AudioStreamPlayer] = []  # Pool of sound effect players.
var _next_sfx := 0  # Which pool player to use next.
var _fade: Tween  # The cross-fade running now.


# Runs once when the game starts: loads the sounds, makes the players and applies the Settings.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keep playing even if the game is paused.
	for track in MUSIC:  # Each music track ...
		_streams[track] = load(MUSIC[track])  # ... is loaded once,
		_set_loop(_streams[track], track in LOOPING)  # ... and set to repeat or to play once.
	for sound in SFX:  # Each sound effect ...
		_streams[sound] = load(SFX[sound])  # ... is loaded once.
	for i in range(2):  # Two music players.
		var player := AudioStreamPlayer.new()  # A new player ...
		player.bus = "Music"  # ... on the Music bus,
		player.finished.connect(_on_music_finished)  # ... that tells us when a track ends,
		add_child(player)  # ... added to the game.
		_music.append(player)  # Keep it.
	for i in range(SFX_PLAYERS):  # The sound effect pool.
		var player := AudioStreamPlayer.new()  # A new player ...
		player.bus = "SFX"  # ... on the SFX bus,
		add_child(player)  # ... added to the game.
		_sfx.append(player)  # Keep it.
	_apply_settings()  # Mute buses that are switched off.
	Save.setting_changed.connect(_on_setting_changed)  # Follow later Settings changes.


# Starts a music track with a cross-fade. `then` names a track to play after a one-time track ends.
func play_music(track: String, then: String = "") -> void:
	_after = then  # Remember what comes next.
	if track == _current:  # Already playing ...
		return  # ... so leave it running.
	_current = track  # The new track.
	var old := _music[_active]  # Player that is fading out.
	_active = 1 - _active  # Switch to the other player.
	var new := _music[_active]  # Player that is fading in.
	new.stream = _streams[track]  # Give it the track (set to repeat or not when it was loaded).
	new.volume_db = -30.0  # Start quiet.
	new.play()  # Start the track.
	if _fade != null and _fade.is_valid():  # An older fade is still running ...
		_fade.kill()  # ... so stop it.
	_fade = create_tween().set_parallel(true)  # Fade both players together.
	_fade.tween_property(new, "volume_db", 0.0, FADE_SECONDS)  # New track up to full.
	_fade.tween_property(old, "volume_db", -40.0, FADE_SECONDS)  # Old track down to silent.
	_fade.chain().tween_callback(old.stop)  # Then stop the old track.


# Sets a music track to repeat (the menu and play loops) or to play once (the win jingle).
# Godot imports OGG music without repeating, so the loops are switched on here when they load.
# The loop files are made so their end runs smoothly into their start (tools/convert_audio.sh).
func _set_loop(stream: AudioStream, loop: bool) -> void:
	var ogg := stream as AudioStreamOggVorbis  # The music is OGG (D-018).
	if ogg != null:  # It is OGG ...
		ogg.loop = loop  # ... so repeat it, or not.


# Runs when a music track reaches its end (only one-time tracks do): start the follow-up track.
func _on_music_finished() -> void:
	if _after != "":  # A follow-up track was named ...
		var next := _after  # ... take it,
		_after = ""  # ... clear it,
		_current = ""  # ... allow a restart,
		play_music(next)  # ... and play it.


# Plays a sound effect by name. `pitch` above 1.0 sounds higher (used for the rising Star sounds).
func play_sfx(sound: String, pitch: float = 1.0) -> void:
	if not _streams.has(sound):  # Unknown name ...
		push_warning("Unknown sound: " + sound)  # ... warn, so the typo is found.
		return  # Stop here.
	var player := _sfx[_next_sfx]  # Next player in the pool.
	_next_sfx = (_next_sfx + 1) % SFX_PLAYERS  # Move along the pool, wrapping round.
	player.stream = _streams[sound]  # Give it the sound.
	player.pitch_scale = pitch  # Set the pitch.
	player.play()  # Play it.


# Runs when a Settings switch changes: re-applies the mutes.
func _on_setting_changed(_key: String, _value: bool) -> void:
	_apply_settings()  # Music or sound effects may have been switched.


# Runs when the game closes: stops the music, so its sound data is freed cleanly
# (a track still playing at exit was reported as a leak).
func _exit_tree() -> void:
	for player in _music:  # Both music players ...
		player.stop()  # ... are stopped,
		player.stream = null  # ... and let go of their track.


# Mutes the Music bus and the SFX bus according to the Settings switches.
func _apply_settings() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not Save.settings.music)  # Music on/off.
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not Save.settings.sfx)  # Sound effects on/off.
