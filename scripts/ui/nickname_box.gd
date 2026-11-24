# The box where the learner types a Nickname (D-030). It keeps only letters, numbers and spaces, up
# to 12 characters, as they are typed, and tells the screen when the Nickname is ready.
# Tapping it opens the phone's keyboard. Used on the Welcome screen and the Profile's Nickname card.
class_name NicknameBox  # Lets the screens and tests write NicknameBox.new("Bea").
extends LineEdit  # Godot's one-line text box.

signal ready_changed(ready: bool)  # Sent after each change: true when the Nickname can be saved.


# Makes the box, starting with `start` in it.
func _init(start: String = "") -> void:
	text = start  # The Nickname so far.
	placeholder_text = "Nickname"  # Grey hint while the box is empty.
	max_length = Profile.MAX_LENGTH  # No more than 12 characters.
	alignment = HORIZONTAL_ALIGNMENT_CENTER  # Text in the middle.
	custom_minimum_size = Vector2(760, 140)  # Big enough for small fingers.
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Centred in the column.
	add_theme_font_override("font", UiKit.font())  # Fredoka.
	add_theme_font_size_override("font_size", 64)  # Big, readable letters.
	add_theme_color_override("font_color", Palette.INK)  # Dark letters.
	add_theme_color_override("font_placeholder_color", Color(Palette.INK, 0.4))  # Faded hint.
	add_theme_color_override("caret_color", Palette.INK)  # Dark typing line.
	add_theme_stylebox_override("normal", UiKit.box(Palette.WHITE, 40))  # White box with the dark outline.
	var focused := UiKit.box(Palette.WHITE, 40)  # The same box while typing ...
	focused.border_color = Palette.BLUE  # ... with a blue outline, so the learner sees where they type.
	add_theme_stylebox_override("focus", focused)  # Use it while typing.
	text_changed.connect(_on_text_changed)  # Check every change.
	text_submitted.connect(func(_done: String) -> void: release_focus())  # The keyboard's Done closes the keyboard.


# Runs after each change: drops signs that are not allowed, and tells the screen whether the Nickname is ready.
func _on_text_changed(new_text: String) -> void:
	var cleaned := Profile.clean(new_text)  # Only letters, numbers and spaces, up to 12.
	if cleaned != new_text:  # Something was dropped ...
		var caret := caret_column - (new_text.length() - cleaned.length())  # ... so the typing line moves back,
		text = cleaned  # ... the box shows the cleaned text,
		caret_column = maxi(caret, 0)  # ... and the typing line stays where the learner was.
	ready_changed.emit(is_ready())  # Tell the screen.


# Returns true when the box holds a Nickname that can be saved.
func is_ready() -> bool:
	return Profile.is_valid(text)  # 1 to 12 allowed characters, not only spaces.


# Returns the Nickname without spaces at the ends.
func nickname() -> String:
	return text.strip_edges()  # Trimmed.
