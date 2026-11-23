# Start-up menu: the first screen. Shows the DiviRush logo and title and a pulsing "Tap to Start".
# Tapping anywhere goes to the Main menu (Game Spec, Screens).
extends ScreenBase  # Shared background, margins and column.

var _leaving := false  # true once a tap was seen, so a second tap does nothing.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020).
	add_spacer(1.0)  # Space above the logo.
	var logo := TextureRect.new()  # The logo picture.
	logo.texture = SpriteSheet.logo()  # Big yellow bubble with a ÷ sign.
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE  # Any size.
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED  # Keep its shape.
	logo.custom_minimum_size = Vector2(440, 440)  # Its size on screen.
	logo.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	column.add_child(logo)  # Show it.
	UiKit.pop_in(logo, 0.1)  # Bounce in.
	UiKit.rock(logo, 5.0, 2.4, 0.6)  # Then rock gently.
	var title := UiKit.title(140)  # Big outlined title.
	column.add_child(title)  # Show it.
	UiKit.pop_in(title, 0.3)  # Bounce in after the logo.
	var tagline := UiKit.label("Quick-tap division!", 56, Palette.WHITE, 14)  # Short tagline.
	column.add_child(tagline)  # Show it.
	UiKit.pop_in(tagline, 0.45)  # Bounce in last.
	add_spacer(1.2)  # Space above the prompt.
	var prompt := UiKit.label("Tap to Start", 80, Palette.WHITE, 20)  # The prompt.
	column.add_child(prompt)  # Show it.
	UiKit.pulse(prompt, 0.1, 1.1)  # Breathe in and out so it catches the eye.
	add_spacer(0.5)  # Space at the bottom.


# Runs for every input event: the first tap or click anywhere opens the Main menu.
# This uses _input, not _unhandled_input, because the layout containers take taps first.
# While the "Leave DiviRush?" card is open, taps belong to its buttons, so they are left alone (D-021).
func _input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton  # Taps arrive as mouse clicks.
	if mouse != null and mouse.pressed and not _leaving and not is_exit_card_open():  # A first tap, with no card open ...
		_leaving = true  # ... is used once,
		Audio.play_sfx("tap")  # ... clicks,
		Game.go_to("main_menu")  # ... and opens the Main menu.


# Back on the Start-up menu would close the game, as Android players expect on a first screen,
# so it first asks with the "Leave DiviRush?" card (D-021).
func go_back() -> void:
	show_exit_card()  # Ask before closing.
