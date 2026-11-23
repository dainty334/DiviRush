# Makes one scene file per screen, so Godot itself writes the .tscn files.
# Each scene is a full-screen Control with its screen script; the script builds the rest in code.
# Run from the project folder with:
#   godot --headless --script res://tools/make_scenes.gd
extends SceneTree  # A SceneTree script runs on its own, without opening a scene.

const SCREENS := [  # Every screen in the game, in play order.
	"start_screen", "main_menu", "how_to_play", "settings_screen",  # Screen names.
	"episode_select", "difficulty_select", "level_select", "play_screen", "level_end",  # Screen names.
	"trophies_screen", "records_screen",  # The Trophies and My Records screens (D-023).
]  # End of the list.


# Runs once after the autoloads (Save, Audio, Game) exist, since the screen scripts use them:
# makes and saves every screen scene, then quits.
func _initialize() -> void:
	for screen in SCREENS:  # Each screen ...
		_make(screen)  # ... gets its scene file.
	quit()  # Close the tool when done.


# Makes one screen scene: a Control named after the screen, with its script, saved as a .tscn.
func _make(screen: String) -> void:
	var root := Control.new()  # The scene's top node.
	root.name = screen.to_pascal_case()  # Example: "PlayScreen".
	root.set_anchors_preset(Control.PRESET_FULL_RECT)  # Fill the window.
	root.set_script(load("res://scripts/screens/%s.gd" % screen))  # Attach the screen's script.
	var scene := PackedScene.new()  # An empty scene.
	scene.pack(root)  # Put the node into it.
	var path := "res://scenes/screens/%s.tscn" % screen  # Where to save it.
	var error := ResourceSaver.save(scene, path)  # Godot writes the file.
	print("saved ", path, " ok" if error == OK else " FAILED")  # Report it.
	root.free()  # Free the node; it was only needed for packing.
