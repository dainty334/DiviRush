# One-time project setup tool. Run it from the project folder with:
#   godot --headless --script res://tools/setup_project.gd
# It lets Godot itself write project.godot and the audio bus layout file,
# so those Godot files stay in the format Godot expects.
extends SceneTree  # A SceneTree script runs on its own, without opening a scene.


# Runs once when the tool starts. Sets every project setting, saves, then quits.
func _init() -> void:
	_set_display()  # Portrait screen size and stretch rules.
	_set_app()  # Start scene, colours and the test addon.
	_set_autoloads()  # The always-loaded helper scripts.
	_save_bus_layout()  # The Music and SFX audio buses.
	var error := ProjectSettings.save()  # Write all changes into project.godot.
	print("project.godot saved: ", error == OK)  # Report success in the console.
	quit()  # Close the tool when done.


# Sets the screen size for a portrait phone, designed at 1080 x 1920 (D-009).
func _set_display() -> void:
	ProjectSettings.set_setting("display/window/size/viewport_width", 1080)  # Design width in pixels.
	ProjectSettings.set_setting("display/window/size/viewport_height", 1920)  # Design height in pixels.
	ProjectSettings.set_setting("display/window/size/window_width_override", 540)  # Half-size window on a PC so it fits the monitor.
	ProjectSettings.set_setting("display/window/size/window_height_override", 960)  # Half-size window height on a PC.
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")  # Scale all 2D and UI to the real screen.
	ProjectSettings.set_setting("display/window/stretch/aspect", "expand")  # Taller or wider phones get extra space, not black bars.
	ProjectSettings.set_setting("display/window/handheld/orientation", 1)  # 1 = portrait only on phones (D-009).
	ProjectSettings.set_setting("application/config/quit_on_go_back", false)  # Android Back goes to the previous screen instead of closing the game.
	ProjectSettings.set_setting("rendering/textures/vram_compression/import_etc2_astc", true)  # Texture compression that Android phones support.
	ProjectSettings.set_setting("rendering/renderer/rendering_method", "gl_compatibility")  # Compatibility renderer (OpenGL ES 3), for low-cost phones (D-016).
	ProjectSettings.set_setting("rendering/renderer/rendering_method.mobile", "gl_compatibility")  # The same on phones, so no Vulkan is needed (D-016).


# Sets the start scene, the start-up colours and turns on the GUT test addon.
func _set_app() -> void:
	ProjectSettings.set_setting("application/run/main_scene", "res://scenes/screens/start_screen.tscn")  # First screen when the game opens.
	ProjectSettings.set_setting("application/boot_splash/bg_color", Color("#4361EE"))  # Blue splash so start-up matches the sky colour.
	ProjectSettings.set_setting("rendering/environment/defaults/default_clear_color", Color("#4361EE"))  # Blue behind every screen.
	ProjectSettings.set_setting("editor_plugins/enabled", PackedStringArray(["res://addons/gut/plugin.cfg"]))  # Show the GUT test panel in the editor.


# Registers the three autoloads. The "*" means Godot makes a node of the script at start.
func _set_autoloads() -> void:
	ProjectSettings.set_setting("autoload/Save", "*res://scripts/autoloads/save_manager.gd")  # Loads and saves progress and settings.
	ProjectSettings.set_setting("autoload/Audio", "*res://scripts/autoloads/audio_manager.gd")  # Plays music and sound effects.
	ProjectSettings.set_setting("autoload/Game", "*res://scripts/autoloads/game_state.gd")  # Remembers the chosen Level and changes screens.


# Makes the Music and SFX buses and saves them, so each can be muted on its own in Settings.
func _save_bus_layout() -> void:
	AudioServer.bus_count = 3  # Bus 0 is Master; add two more.
	AudioServer.set_bus_name(1, "Music")  # Bus 1 carries the music tracks.
	AudioServer.set_bus_send(1, "Master")  # Music flows into Master.
	AudioServer.set_bus_name(2, "SFX")  # Bus 2 carries the sound effects.
	AudioServer.set_bus_send(2, "Master")  # Sound effects flow into Master.
	var layout := AudioServer.generate_bus_layout()  # Turn the buses into a saveable resource.
	var error := ResourceSaver.save(layout, "res://default_bus_layout.tres")  # Godot loads this file by default.
	print("bus layout saved: ", error == OK)  # Report success in the console.
