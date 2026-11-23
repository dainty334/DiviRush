# Settings: Music, Sound effects and Vibration on/off, saved on the device (D-008, D-009, D-010).
extends ScreenBase  # Shared background, margins and column.

const ROWS := [  # [save key, icon, label]
	["music", UiKit.Icon.MUSIC, "Music"],  # One switch as [save key, icon, name].
	["sfx", UiKit.Icon.SOUND, "Sound effects"],  # One switch as [save key, icon, name].
	["vibration", UiKit.Icon.VIBRATION, "Vibration"],  # One switch as [save key, icon, name].
]  # End of the list.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020), so the Music switch can be heard working.
	add_header("Settings")  # Back button and title.
	add_spacer(0.2)  # A little space.
	var delay := 0.05  # Pop-in delay, growing per row.
	for row in ROWS:  # Each switch ...
		var card := _switch_row(row[0], row[1], row[2])  # ... becomes a row card,
		column.add_child(card)  # ... shown in the column,
		UiKit.pop_in(card, delay)  # ... bouncing in.
		delay += 0.1  # Next row a little later.
	add_spacer(1.0)  # Push the button down.
	var done := UiKit.button("Done", Palette.GREEN)  # Leave Settings.
	done.pressed.connect(go_back)  # Back to the Main menu.
	column.add_child(done)  # Show it.


# Makes one row: icon, name, and an ON/OFF switch button.
func _switch_row(key: String, which: int, text: String) -> PanelContainer:
	var card := PanelContainer.new()  # White row card.
	card.add_theme_stylebox_override("panel", UiKit.box(Palette.WHITE, 56))  # Rounded with a thick outline.
	var row := HBoxContainer.new()  # Icon, name and switch side by side.
	row.add_theme_constant_override("separation", 28)  # Space between them.
	card.add_child(row)  # Put the row on the card.
	row.add_child(UiKit.icon(which, 96))  # The icon.
	var name_label := UiKit.label(text, 56, Palette.INK)  # The switch name.
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT  # Lined up on the left.
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the free width.
	row.add_child(name_label)  # Add it.
	var toggle := UiKit.button("", Palette.GREEN, Vector2(220, 120), 52)  # The ON/OFF button.
	toggle.toggle_mode = true  # It stays on or off.
	toggle.button_pressed = Save.settings[key]  # Start from the saved value.
	_show_switch(toggle, toggle.button_pressed)  # Show ON or OFF.
	toggle.toggled.connect(_on_toggled.bind(key, toggle))  # React to taps.
	row.add_child(toggle)  # Add it.
	return card  # Hand back the row card.


# Shows a switch as green ON or grey OFF.
func _show_switch(toggle: Button, on: bool) -> void:
	toggle.text = "ON" if on else "OFF"  # The word.
	UiKit.style_button(toggle, Palette.GREEN if on else Palette.LOCKED)  # The colour.


# Runs when a switch is tapped: saves it, updates its look, and buzzes once if Vibration was turned on.
func _on_toggled(on: bool, key: String, toggle: Button) -> void:
	Save.set_setting(key, on)  # Save the new value (Audio mutes or unmutes its bus).
	_show_switch(toggle, on)  # Show the new value.
	if key == "vibration" and on:  # Vibration just switched on ...
		Game.vibrate()  # ... so buzz once to show it works.


# Back returns to the Main menu.
func go_back() -> void:
	Game.go_to("main_menu")  # Main menu.
