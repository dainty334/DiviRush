# Welcome screen (D-030): shown once, after "Tap to Start", to a first-time player, and to a learner
# whose save from an older version has no Nickname yet. Ana and Migo say hello; the learner types a
# Nickname and picks a Buddy; Next saves both and opens the Main menu.
extends ScreenBase  # Shared background, margins and column.

var _nickname: NicknameBox  # Where the Nickname is typed.
var _picker: BuddyPicker  # Ana, Migo or Both.
var _next: Button  # Saves the choices and opens the Main menu; off until a Nickname is typed.


# Builds the screen. Called once by ScreenBase when the screen opens.
func _build() -> void:
	Audio.play_music("menu")  # Main menu area music (D-020).
	column.add_theme_constant_override("separation", 26)  # Even gaps between the parts.
	add_spacer(0.3)  # A little sky at the top.
	column.add_child(_make_greeting())  # Ana and Migo say hello.
	add_spacer(0.2)  # Space under the greeting.
	column.add_child(UiKit.label("What's your nickname?", 64, Palette.WHITE, 16))  # The first question.
	_nickname = NicknameBox.new(Save.profile.nickname)  # The box, with any Nickname already given.
	column.add_child(_nickname)  # Show it; it sits high, so the phone's keyboard does not cover it.
	column.add_child(UiKit.label("Use a nickname, not your full name.", 40, Palette.WHITE, 10))  # Keeps the child's real name out of the game.
	add_spacer(0.3)  # Space before the second question.
	column.add_child(UiKit.label("Who's your buddy?", 64, Palette.WHITE, 16))  # The second question.
	_picker = BuddyPicker.new(Save.profile.buddy)  # Ana, Migo or Both, starting at Both.
	column.add_child(_picker)  # Show the three tiles.
	add_spacer(1.0)  # Push Next to the bottom.
	_next = UiKit.icon_button("Next", UiKit.Icon.PLAY, Palette.GREEN, Vector2(700, 170), 72)  # The big green Next.
	_next.pressed.connect(_on_next)  # Save and go on.
	column.add_child(_next)  # Show it.
	_nickname.ready_changed.connect(_show_next)  # Next follows the Nickname box.
	_show_next(_nickname.is_ready())  # Off until a Nickname is typed.


# Makes the greeting: both faces and a white speech bubble beside them.
func _make_greeting() -> HBoxContainer:
	var row := HBoxContainer.new()  # Faces and bubble side by side.
	row.alignment = BoxContainer.ALIGNMENT_CENTER  # Centred across.
	row.add_theme_constant_override("separation", 24)  # Space between them.
	var faces := BuddyFace.new(Profile.BOTH, 190.0)  # Ana's and Migo's faces.
	faces.size_flags_vertical = Control.SIZE_SHRINK_CENTER  # Centred up and down.
	row.add_child(faces)  # Add them.
	var bubble := PanelContainer.new()  # The speech bubble.
	var style := UiKit.box(Palette.WHITE, 48)  # White, round and outlined.
	style.set_content_margin_all(28)  # Room inside.
	bubble.add_theme_stylebox_override("panel", style)  # Use this look.
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Not a button.
	var words := UiKit.label("Hi! We're Ana and Migo.\nWelcome to DiviRush!", 46, Palette.INK)  # The greeting.
	words.custom_minimum_size.x = 560.0  # Wide enough for each line.
	bubble.add_child(words)  # Put the words in the bubble.
	row.add_child(bubble)  # Add the bubble.
	UiKit.pop_in(row, 0.1)  # Bounce in.
	return row  # Hand back the row.


# Turns Next on when the Nickname is ready, and off when it is not.
func _show_next(ready: bool) -> void:
	_next.disabled = not ready  # Off until 1 to 12 allowed characters are typed.


# Keeps the Nickname and the Buddy and writes them to the save file. Called by Next.
func save_choices() -> void:
	Save.set_profile(_nickname.nickname(), _picker.selected)  # Saved on the phone only (D-030).


# Next: saves the choices and opens the Main menu.
func _on_next() -> void:
	if not _nickname.is_ready():  # No Nickname yet ...
		return  # ... so stay (Next is off anyway).
	save_choices()  # Keep them.
	Game.go_to("main_menu")  # On to the Main menu.


# Back returns to the Start-up menu; the Welcome screen shows again next time.
func go_back() -> void:
	Game.go_to("start_screen")  # First screen.
