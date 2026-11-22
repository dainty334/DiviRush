# Main menu: Play, How to Play, Settings and Exit (D-008).
extends ScreenBase  # Shared background, margins and column.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Calm menu music.
	add_spacer(0.6)  # Space at the top.
	var logo := TextureRect.new()  # Small logo.
	logo.texture = SpriteSheet.logo()  # Yellow ÷ bubble.
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Any size.
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Keep its shape.
	logo.custom_minimum_size = Vector2(260, 260)  # Its size on screen.
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	column.add_child(logo)  # Show it.
	UiKit.rock(logo, 6.0, 2.4)  # Rock gently.
	column.add_child(UiKit.title(110))  # Title.
	add_spacer(0.6)  # Space above the buttons.
	_add_menu_button("Play", Palette.GREEN, 190, 84, _on_play, 0.05)  # Biggest button first.
	_add_menu_button("How to Play", Palette.YELLOW, 150, 64, _on_how_to_play, 0.15)  # Rules screen.
	_add_menu_button("Settings", Palette.WHITE, 150, 64, _on_settings, 0.25)  # Switches screen.
	_add_menu_button("Exit", Palette.PINK, 150, 64, _on_exit, 0.35)  # Close the game.
	add_spacer(1.0)  # Space at the bottom.


# Adds one menu button that pops in after `delay` and then rocks gently.
func _add_menu_button(text: String, colour: Color, height: float, font_size: int, action: Callable, delay: float) -> void:
	var button := UiKit.button(text, colour, Vector2(760, height), font_size)  # Chunky button.
	button.pressed.connect(action)  # What it does.
	column.add_child(button)  # Show it.
	UiKit.pop_in(button, delay)  # Bounce in one after another.
	UiKit.rock(button, 1.5, 1.8, delay * 4.0)  # Then rock, each at its own time.


# Play opens Episode select.
func _on_play() -> void:
	Game.go_to("episode_select")  # Next screen in the path.


# How to Play opens the rules screen.
func _on_how_to_play() -> void:
	Game.go_to("how_to_play")  # Rules screen.


# Settings opens the switches screen.
func _on_settings() -> void:
	Game.go_to("settings_screen")  # Switches screen.


# Exit saves and closes the game.
func _on_exit() -> void:
	Game.quit_game()  # Save and close.


# Back on the Main menu returns to the Start-up menu.
func go_back() -> void:
	Game.go_to("start_screen")  # First screen.
