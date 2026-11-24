# Makes one scene file per screen, so Godot itself writes the .tscn files.
# Each scene is a full-screen Control with its screen script; the script builds the rest in code.
# Run from the project folder with:
#   godot --headless --script res://tools/make_scenes.gd
# To make only some screens, so the others are left as they are, name them after "--":
#   godot --headless --script res://tools/make_scenes.gd -- welcome_screen profile_screen
extends SceneTree  # A SceneTree script runs on its own, without opening a scene.

const SCREENS := [  # Every screen in the game, in play order.
	"start_screen", "welcome_screen", "main_menu", "profile_screen", "how_to_play", "settings_screen",  # Screen names (Welcome and Profile, D-030).
	"episode_select", "difficulty_select", "level_select", "play_screen", "level_end",  # Screen names.
	"trophies_screen",  # The Trophies screen, with its Records tab (D-023, D-030).
]  # End of the list.


# Runs once after the autoloads (Save, Audio, Game) exist, since the screen scripts use them:
# makes and saves the named screen scenes (every screen when none are named), then quits.
func _initialize() -> void:
	var wanted := OS.get_cmdline_user_args()  # Screen names given after "--", if any.
	for screen in SCREENS:  # Each screen ...
		if wanted.is_empty() or wanted.has(screen):  # ... that was asked for ...
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
