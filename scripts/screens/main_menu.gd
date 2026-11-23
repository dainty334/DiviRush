# Main menu, play first (D-025), on its own candy sky (D-022), with no title:
#   top row     three small count pills (Stars, Trophies, Levels passed) and an Exit door at the right
#   middle      the talking student mascot, Ana or Migo (D-024), who talks only when tapped
#   Play        one huge breathing Play button
#   bottom bar  How to Play, Trophies, My Records and Settings as icons in one white bar
extends ScreenBase  # Shared background, margins and column.

const BAR_BUTTON_SIZE := Vector2(232, 176)  # Each of the four bottom-bar buttons, so all four fit in one bar.

static var _turn := 0  # Counts Main menu visits while the game runs, so Ana and Migo take turns (D-024).

var _buttons: Array[Button] = []  # Play, the four bottom-bar buttons, then Exit.
var _play_breath: CenterContainer  # The box around Play that grows and shrinks, so Play's own size is free for its tap bounce.
var _mascot: Mascot  # Ana or Migo, in the middle.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020).
	column.add_theme_constant_override("separation", 28)  # Even gaps between the parts.
	var exit := _add_top_row()  # Count pills and the Exit door.
	add_spacer(1.0)  # Sky above the mascot, where its speech bubble floats when tapped (D-027).
	_add_mascot()  # The big talking mascot.
	add_spacer(0.3)  # Space above Play.
	_add_play()  # The huge Play button.
	add_spacer(0.3)  # Space above the bottom bar.
	_add_bottom_bar()  # How to Play, Trophies, My Records and Settings.
	_buttons.append(exit)  # Exit is listed last, after the main choices.


# The Main menu has its own candy sky: pink to lavender with numbers and ÷ signs (D-022).
func sky_look() -> int:
	return SkyBackground.Look.CANDY  # Candy look.


# Adds the top row: three small count pills on the left and the Exit door on the right.
# Returns the Exit button, so it can be listed after the main choices.
func _add_top_row() -> Button:
	var row := HBoxContainer.new()  # Pills and Exit side by side.
	row.add_theme_constant_override("separation", 14)  # Space between the pills.
	column.add_child(row)  # Show it first, because animations need it on screen.
	row.add_child(_make_pill(UiKit.Icon.STAR, Save.progress.total_stars(), Progress.MAX_STARS))  # Stars earned.
	row.add_child(_make_pill(UiKit.Icon.TROPHY, Save.records.trophies.size(), Trophies.ALL.size()))  # Trophies earned.
	row.add_child(_make_pill(UiKit.Icon.CHART, Save.progress.levels_passed(), Progress.LEVEL_TOTAL))  # Levels passed.
	var gap := Control.new()  # Pushes Exit to the right edge.
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Take the free width.
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	row.add_child(gap)  # Add it.
	var exit := UiKit.icon_button("Exit", UiKit.Icon.EXIT, Palette.PINK, Vector2(210, 96), 38, 52.0, 22.0)  # A small pink door button, hard to tap by mistake.
	exit.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Not stretched tall.
	exit.pressed.connect(_on_exit)  # It asks first (D-021).
	row.add_child(exit)  # At the right.
	UiKit.pop_in(exit, 0.3)  # Bounce in.
	return exit  # Hand it back.


# Makes one small white count pill: an icon and "earned/total", for example "5/180".
func _make_pill(which: int, earned: int, total: int) -> PanelContainer:
	var pill := PanelContainer.new()  # The pill.
	var style := UiKit.box(Palette.WHITE, 40, 5)  # White, round, with a thin dark outline.
	style.set_content_margin_all(6)  # A little space inside ...
	style.content_margin_left = 14  # ... more at the ends,
	style.content_margin_right = 18  # ... so it looks round.
	pill.add_theme_stylebox_override("panel", style)  # Use this look.
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Not stretched tall.
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	var row := HBoxContainer.new()  # Icon beside the number.
	row.add_theme_constant_override("separation", 6)  # Close together.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go through.
	row.add_child(UiKit.icon(which, 48))  # The icon.
	row.add_child(UiKit.label("%d/%d" % [earned, total], 38, Palette.INK))  # The count.
	pill.add_child(row)  # Put them in the pill.
	UiKit.pop_in(pill, 0.05)  # Bounce in.
	return pill  # Hand back the pill.


# Adds the talking mascot in the middle: Ana and Migo take turns each time the Main menu opens (D-024).
# The mascot talks only when tapped (D-025); its lines come from the learner's own progress and Trophies.
func _add_mascot() -> void:
	var who: String = MascotLines.NAMES[_turn % MascotLines.NAMES.size()]  # Whose turn it is.
	_turn += 1  # The other one next time.
	_mascot = Mascot.new(who, MascotLines.lines_for(who, Save.progress, Save.records))  # The mascot and what it will say.
	_mascot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred.
	column.add_child(_mascot)  # Show it; it drops in by itself with a bounce (D-027).


# Adds the huge Play button, which breathes so the eye goes to it first (D-017, kept by D-025).
func _add_play() -> void:
	_play_breath = CenterContainer.new()  # The box that breathes around Play.
	_play_breath.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred, as wide as Play.
	_play_breath.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to Play itself.
	column.add_child(_play_breath)  # Play's place in the column.
	_add_button(_play_breath, UiKit.icon_button("Play", UiKit.Icon.PLAY, Palette.GREEN, Vector2(900, 210), 92), _on_play, 0.15)  # The only big button.
	UiKit.pulse(_play_breath, 0.05, 1.2)  # Breathes: 5% bigger and back every 1.2 s.


# Adds the bottom bar: one white bar with How to Play, Trophies, My Records and Settings (D-025).
func _add_bottom_bar() -> void:
	var bar := PanelContainer.new()  # The white bar.
	var style := UiKit.box(Palette.WHITE, 48)  # White, round and outlined.
	style.set_content_margin_all(8)  # A little room inside.
	bar.add_theme_stylebox_override("panel", style)  # Use this look.
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred, as wide as its buttons.
	column.add_child(bar)  # Show it first, because animations need it on screen.
	UiKit.pop_in(bar, 0.2)  # Bounce in.
	var row := HBoxContainer.new()  # The four buttons side by side.
	row.add_theme_constant_override("separation", 4)  # Close together.
	bar.add_child(row)  # Put them in the bar.
	_add_button(row, UiKit.bar_button("How to Play", UiKit.Icon.HELP, BAR_BUTTON_SIZE, 34), _on_how_to_play, -1.0)  # Rules screen.
	_add_button(row, UiKit.bar_button("Trophies", UiKit.Icon.TROPHY, BAR_BUTTON_SIZE, 34), _on_trophies, -1.0)  # Trophies screen (D-023).
	_add_button(row, UiKit.bar_button("My Records", UiKit.Icon.CHART, BAR_BUTTON_SIZE, 34), _on_records, -1.0)  # My Records screen (D-023).
	_add_button(row, UiKit.bar_button("Settings", UiKit.Icon.GEAR, BAR_BUTTON_SIZE, 34), _on_settings, -1.0)  # Switches screen.


# Adds one button to `parent` and lists it; it does `action` when tapped. A `delay` of 0 or more
# makes it pop in after that many seconds; the bar's buttons pop in with the bar instead.
func _add_button(parent: Control, button: Button, action: Callable, delay: float) -> void:
	button.pressed.connect(action)  # What it does.
	parent.add_child(button)  # Show it.
	if delay >= 0.0:  # It pops in on its own ...
		UiKit.pop_in(button, delay)  # ... after the delay.
	_buttons.append(button)  # Remember it.


# Play opens Episode select.
func _on_play() -> void:
	Game.go_to("episode_select")  # Next screen in the path.


# How to Play opens the rules screen.
func _on_how_to_play() -> void:
	Game.go_to("how_to_play")  # Rules screen.


# Trophies opens the Trophies screen (D-023).
func _on_trophies() -> void:
	Game.go_to("trophies_screen")  # Trophies screen.


# My Records opens the learner's game records (D-023).
func _on_records() -> void:
	Game.go_to("records_screen")  # My Records screen.


# Settings opens the switches screen.
func _on_settings() -> void:
	Game.go_to("settings_screen")  # Switches screen.


# Exit first asks with the "Leave DiviRush?" card; its Exit button saves and closes the game (D-021).
func _on_exit() -> void:
	show_exit_card()  # Ask before closing.


# Back on the Main menu returns to the Start-up menu.
func go_back() -> void:
	Game.go_to("start_screen")  # First screen.
