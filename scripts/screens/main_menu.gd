# Main menu, play first (D-025), on its own candy sky (D-022), with no title:
#   top left    the Profile pill: the Buddy's face and the Nickname; it opens the Profile (D-030)
#   middle      the talking student mascot, Ana or Migo as the Buddy choice says (D-024, D-030), who talks only when tapped
#   Play        one huge breathing Play button
#   bottom bar  How to Play, Trophies, Settings and Exit as icons in one white bar (D-030)
extends ScreenBase  # Shared background, margins and column.

const BAR_BUTTON_SIZE := Vector2(232, 176)  # Each of the four bottom-bar buttons, so all four fit in one bar.
const PILL_FACE := 84.0  # The face on the Profile pill.

static var _turn := 0  # Counts Main menu visits while the game runs, so Ana and Migo take turns with "Both" (D-024).

var _buttons: Array[Button] = []  # Play, then the four bottom-bar buttons; Exit is last.
var _profile_button: Button  # The Profile pill at the top left (D-030).
var _play_breath: CenterContainer  # The box around Play that grows and shrinks, so Play's own size is free for its tap bounce.
var _mascot: Mascot  # Ana or Migo, in the middle.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020).
	column.add_theme_constant_override("separation", 28)  # Even gaps between the parts.
	_add_top_row()  # The Profile pill at the top left.
	add_spacer(1.0)  # Sky above the mascot, where its speech bubble floats when tapped (D-027).
	_add_mascot()  # The big talking mascot.
	add_spacer(0.3)  # Space above Play.
	_add_play()  # The huge Play button.
	add_spacer(0.3)  # Space above the bottom bar.
	_add_bottom_bar()  # How to Play, Trophies, Settings and Exit.


# The Main menu has its own candy sky: pink to lavender with numbers and ÷ signs (D-022).
func sky_look() -> int:
	return SkyBackground.Look.CANDY  # Candy look.


# Adds the top row: the Profile pill at the top left, with the Buddy's face and the Nickname (D-030).
# The count pills and the Exit door that were here moved to the Profile and the bottom bar.
func _add_top_row() -> void:
	var row := HBoxContainer.new()  # The pill, kept to the left.
	column.add_child(row)  # Show it first, because animations need it on screen.
	_profile_button = UiKit.card_button(Palette.WHITE, Vector2.ZERO, 54)  # A white round pill button.
	_profile_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN  # At the left edge.
	_profile_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Not stretched tall.
	var inside := HBoxContainer.new()  # Face beside the Nickname.
	inside.add_theme_constant_override("separation", 14)  # A little space between them.
	inside.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred on the pill.
	inside.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Taps go to the pill.
	var face := BuddyFace.new(Save.profile.buddy, PILL_FACE)  # The Buddy's small face, or both faces.
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Centred up and down.
	inside.add_child(face)  # Add it.
	inside.add_child(UiKit.label(Save.profile.nickname, 46, Palette.INK))  # The Nickname.
	var featured := Save.profile.featured  # The Featured Trophy, if one was picked (D-031).
	if featured != "" and Save.records.has_trophy(featured):  # One is picked and earned ...
		var trophy := UiKit.trophy_picture(featured, 70, true)  # ... its small picture,
		trophy.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # ... centred up and down,
		inside.add_child(trophy)  # ... after the Nickname.
	_profile_button.add_child(inside)  # Put them on the pill.
	inside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # Fill the pill ...
	inside.offset_left = 16  # ... with room at the left,
	inside.offset_right = -40  # ... and more at the right, so the Nickname clears the round edge.
	_profile_button.custom_minimum_size = inside.get_combined_minimum_size() + Vector2(72, 36)  # As big as the face and Nickname need, plus the edges.
	_profile_button.pressed.connect(_on_profile)  # Tapping it opens the Profile.
	row.add_child(_profile_button)  # At the left.
	UiKit.pop_in(_profile_button, 0.05)  # Bounce in.


# Adds the talking mascot in the middle: the learner's Buddy (D-030). With "Both", Ana and Migo take
# turns each time the Main menu opens (D-024). The mascot talks only when tapped (D-025); its lines
# come from the learner's own progress and Trophies.
func _add_mascot() -> void:
	var names := Save.profile.mascots()  # Ana, Migo, or both in turn.
	var who: String = names[_turn % names.size()]  # Whose turn it is.
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


# Adds the bottom bar: one white bar with How to Play, Trophies, Settings and Exit (D-025, D-030).
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
	_add_button(row, UiKit.bar_button("Trophies", UiKit.Icon.TROPHY, BAR_BUTTON_SIZE, 34), _on_trophies, -1.0)  # Trophies screen, with the Records tab (D-023, D-030).
	_add_button(row, UiKit.bar_button("Settings", UiKit.Icon.GEAR, BAR_BUTTON_SIZE, 34), _on_settings, -1.0)  # Switches screen.
	_add_button(row, UiKit.bar_button("Exit", UiKit.Icon.EXIT, BAR_BUTTON_SIZE, 34), _on_exit, -1.0)  # Asks first with the "Leave DiviRush?" card (D-021, D-030).


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


# The Profile pill opens the learner's Profile (D-030).
func _on_profile() -> void:
	Game.go_to("profile_screen")  # Profile screen.


# Settings opens the switches screen.
func _on_settings() -> void:
	Game.go_to("settings_screen")  # Switches screen.


# Exit first asks with the "Leave DiviRush?" card; its Exit button saves and closes the game (D-021).
func _on_exit() -> void:
	show_exit_card()  # Ask before closing.


# Back on the Main menu returns to the Start-up menu.
func go_back() -> void:
	Game.go_to("start_screen")  # First screen.
